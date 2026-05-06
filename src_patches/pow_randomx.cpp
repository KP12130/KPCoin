// Copyright (c) 2009-2010 Satoshi Nakamoto
// Copyright (c) 2009-2022 The Bitcoin Core developers
// Copyright (c) 2024-2026 KPCoin Developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <pow.h>

#include <arith_uint256.h>
#include <chain.h>
#include <crypto/randomx_wrapper.h>
#include <primitives/block.h>
#include <uint256.h>
#include <util/check.h>
#include <logging.h>
#include <hash.h>
#include <streams.h>

#include <cstring>

/**
 * KPCoin uses RandomX proof-of-work (same as Monero).
 * 
 * Key rotation: Every RANDOMX_KEY_INTERVAL (2048) blocks, the RandomX
 * key changes. The key is derived from the hash of a previous block.
 * For the first epoch (blocks 0-2047), a fixed genesis key is used.
 *
 * Difficulty adjustment: Retargets every ~960 blocks (~24 hours) to
 * maintain the 90-second block time target.
 */

std::pair<std::vector<unsigned char>, int> GetRandomXKey(
    const CBlockIndex* pindexPrev,
    const Consensus::Params& params)
{
    int nNextHeight = (pindexPrev ? pindexPrev->nHeight + 1 : 0);
    int keyBlockHeight = RandomXWrapper::GetKeyBlockHeight(nNextHeight);

    if (keyBlockHeight < 0) {
        // Use genesis key for early blocks
        const char* genesisKey = RANDOMX_GENESIS_KEY;
        std::vector<unsigned char> key(genesisKey, genesisKey + strlen(genesisKey));
        return {key, -1};
    }

    // Walk back to find the key block
    const CBlockIndex* pKeyBlock = pindexPrev;
    while (pKeyBlock && pKeyBlock->nHeight > keyBlockHeight) {
        pKeyBlock = pKeyBlock->pprev;
    }

    if (!pKeyBlock || pKeyBlock->nHeight != keyBlockHeight) {
        // Fallback to genesis key if we can't find the key block
        const char* genesisKey = RANDOMX_GENESIS_KEY;
        std::vector<unsigned char> key(genesisKey, genesisKey + strlen(genesisKey));
        return {key, -1};
    }

    // Use the key block's hash as the RandomX key
    const uint256& keyBlockHash = pKeyBlock->GetBlockHash();
    std::vector<unsigned char> key(keyBlockHash.begin(), keyBlockHash.end());
    return {key, keyBlockHeight};
}

uint256 GetRandomXBlockHash(const CBlockHeader& header, int nHeight,
                            const uint256& keyHash)
{
    // Serialize the block header
    CDataStream ss(SER_NETWORK, PROTOCOL_VERSION);
    ss << header;

    // Determine the key
    std::vector<unsigned char> key;
    int keyBlockHeight = RandomXWrapper::GetKeyBlockHeight(nHeight);

    if (keyBlockHeight < 0) {
        // Genesis key
        const char* genesisKey = RANDOMX_GENESIS_KEY;
        key.assign(genesisKey, genesisKey + strlen(genesisKey));
    } else {
        key.assign(keyHash.begin(), keyHash.end());
    }

    // Compute RandomX hash
    RandomXWrapper& rx = RandomXWrapper::GetInstance();
    return rx.Hash(
        reinterpret_cast<const unsigned char*>(ss.data()), ss.size(),
        key.data(), key.size()
    );
}

unsigned int GetNextWorkRequired(const CBlockIndex* pindexLast,
                                 const CBlockHeader* pblock,
                                 const Consensus::Params& params)
{
    assert(pindexLast != nullptr);
    unsigned int nProofOfWorkLimit = UintToArith256(params.powLimit).GetCompact();

    // Special rule for first retarget period
    if ((pindexLast->nHeight + 1) < params.DifficultyAdjustmentInterval()) {
        return nProofOfWorkLimit;
    }

    // KPCoin: No special minimum difficulty rules
    // (Bitcoin has special rules for testnet, we remove those for mainnet)

    // Only change difficulty once per interval
    if ((pindexLast->nHeight + 1) % params.DifficultyAdjustmentInterval() != 0) {
        return pindexLast->nBits;
    }

    // Go back by the full retarget interval
    int nHeightFirst = pindexLast->nHeight - (params.DifficultyAdjustmentInterval() - 1);
    assert(nHeightFirst >= 0);
    const CBlockIndex* pindexFirst = pindexLast;
    for (int i = 0; pindexFirst && i < (int)params.DifficultyAdjustmentInterval() - 1; i++) {
        pindexFirst = pindexFirst->pprev;
    }
    assert(pindexFirst);

    return CalculateNextWorkRequired(pindexLast, pindexFirst->GetBlockTime(), params);
}

unsigned int CalculateNextWorkRequired(const CBlockIndex* pindexLast,
                                       int64_t nFirstBlockTime,
                                       const Consensus::Params& params)
{
    if (params.fPowNoRetargeting)
        return pindexLast->nBits;

    // Limit adjustment step
    int64_t nActualTimespan = pindexLast->GetBlockTime() - nFirstBlockTime;
    
    // KPCoin: Allow wider adjustment range for faster response
    // Minimum: 1/4 of target timespan
    // Maximum: 4x target timespan
    int64_t nTargetTimespan = params.nPowTargetTimespan;
    
    if (nActualTimespan < nTargetTimespan / 4)
        nActualTimespan = nTargetTimespan / 4;
    if (nActualTimespan > nTargetTimespan * 4)
        nActualTimespan = nTargetTimespan * 4;

    // Retarget
    const arith_uint256 bnPowLimit = UintToArith256(params.powLimit);
    arith_uint256 bnNew;
    bnNew.SetCompact(pindexLast->nBits);
    bnNew *= nActualTimespan;
    bnNew /= nTargetTimespan;

    if (bnNew > bnPowLimit)
        bnNew = bnPowLimit;

    return bnNew.GetCompact();
}

bool CheckProofOfWork(uint256 hash, unsigned int nBits,
                      const Consensus::Params& params)
{
    bool fNegative;
    bool fOverflow;
    arith_uint256 bnTarget;

    bnTarget.SetCompact(nBits, &fNegative, &fOverflow);

    // Check range
    if (fNegative || bnTarget == 0 || fOverflow ||
        bnTarget > UintToArith256(params.powLimit))
        return false;

    // Check proof of work matches claimed amount
    if (UintToArith256(hash) > bnTarget)
        return false;

    return true;
}

bool CheckProofOfWorkRandomX(const CBlockHeader& header, int nHeight,
                             const uint256& keyHash, unsigned int nBits,
                             const Consensus::Params& params)
{
    // Compute RandomX hash of the block header
    uint256 hash = GetRandomXBlockHash(header, nHeight, keyHash);

    // Check if the hash meets the difficulty target
    return CheckProofOfWork(hash, nBits, params);
}

bool PermittedDifficultyTransition(const Consensus::Params& params,
                                   int64_t height, uint32_t old_nbits,
                                   uint32_t new_nbits)
{
    if (params.fPowAllowMinDifficultyBlocks) return true;

    // The difficulty can change by at most a factor of 4 per retarget
    if (height % params.DifficultyAdjustmentInterval() == 0) {
        int64_t smallest_timespan = params.nPowTargetTimespan / 4;
        int64_t largest_timespan = params.nPowTargetTimespan * 4;

        const arith_uint256 pow_limit = UintToArith256(params.powLimit);

        arith_uint256 observed_new_target;
        observed_new_target.SetCompact(new_nbits);

        // Calculate the largest difficulty value possible:
        arith_uint256 largest_difficulty_target;
        largest_difficulty_target.SetCompact(old_nbits);
        largest_difficulty_target *= largest_timespan;
        largest_difficulty_target /= params.nPowTargetTimespan;

        if (largest_difficulty_target > pow_limit) {
            largest_difficulty_target = pow_limit;
        }

        // Round and then compare
        arith_uint256 maximum_new_target;
        maximum_new_target.SetCompact(largest_difficulty_target.GetCompact());
        if (maximum_new_target < observed_new_target) return false;

        // Calculate the smallest difficulty value possible:
        arith_uint256 smallest_difficulty_target;
        smallest_difficulty_target.SetCompact(old_nbits);
        smallest_difficulty_target *= smallest_timespan;
        smallest_difficulty_target /= params.nPowTargetTimespan;

        if (smallest_difficulty_target > pow_limit) {
            smallest_difficulty_target = pow_limit;
        }

        arith_uint256 minimum_new_target;
        minimum_new_target.SetCompact(smallest_difficulty_target.GetCompact());
        if (minimum_new_target > observed_new_target) return false;
    } else if (old_nbits != new_nbits) {
        return false;
    }
    return true;
}
