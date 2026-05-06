// Copyright (c) 2009-2010 Satoshi Nakamoto
// Copyright (c) 2009-2022 The Bitcoin Core developers
// Copyright (c) 2024-2026 KPCoin Developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef KPCOIN_POW_H
#define KPCOIN_POW_H

#include <consensus/params.h>
#include <uint256.h>

#include <optional>

class CBlockHeader;
class CBlockIndex;
class arith_uint256;

/**
 * Compute the RandomX hash of a block header.
 * This replaces Bitcoin's SHA-256d with RandomX for ASIC resistance.
 *
 * @param header     The block header to hash
 * @param nHeight    Block height (used to determine RandomX key)
 * @param keyHash    Hash of the key block (or empty for genesis key)
 * @return           256-bit RandomX hash
 */
uint256 GetRandomXBlockHash(const CBlockHeader& header, int nHeight,
                            const uint256& keyHash);

/**
 * Get the RandomX key for a given block height.
 * @param pindexPrev Previous block index (can be nullptr for genesis)
 * @param params     Consensus parameters
 * @return           The key to use for RandomX, and the key block height
 */
std::pair<std::vector<unsigned char>, int> GetRandomXKey(
    const CBlockIndex* pindexPrev,
    const Consensus::Params& params);

unsigned int GetNextWorkRequired(const CBlockIndex* pindexLast,
                                 const CBlockHeader* pblock,
                                 const Consensus::Params& params);

unsigned int CalculateNextWorkRequired(const CBlockIndex* pindexLast,
                                       int64_t nFirstBlockTime,
                                       const Consensus::Params& params);

/** Check whether a block hash satisfies the proof-of-work requirement */
bool CheckProofOfWork(uint256 hash, unsigned int nBits,
                      const Consensus::Params& params);

/**
 * Check proof of work for a block header using RandomX.
 * This is the main validation entry point.
 */
bool CheckProofOfWorkRandomX(const CBlockHeader& header, int nHeight,
                             const uint256& keyHash, unsigned int nBits,
                             const Consensus::Params& params);

/**
 * Return false if the proof-of-work requirement specified by new_nbits at a
 * given height is not possible, given the proof-of-work on the prior block
 * as specified by old_nbits.
 */
bool PermittedDifficultyTransition(const Consensus::Params& params,
                                   int64_t height, uint32_t old_nbits,
                                   uint32_t new_nbits);

#endif // KPCOIN_POW_H
