// Copyright (c) 2010 Satoshi Nakamoto
// Copyright (c) 2009-2021 The KPCoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <kernel/chainparams.h>

#include <chainparamsseeds.h>
#include <consensus/amount.h>
#include <consensus/merkle.h>
#include <consensus/params.h>
#include <hash.h>
#include <kernel/messagestartchars.h>
#include <logging.h>
#include <primitives/block.h>
#include <primitives/transaction.h>
#include <script/interpreter.h>
#include <script/script.h>
#include <uint256.h>
#include <util/chaintype.h>
#include <util/strencodings.h>

#include <algorithm>
#include <cassert>
#include <cstdint>
#include <cstring>
#include <type_traits>
#include <iostream>

static CBlock CreateGenesisBlock(const char* pszTimestamp, const CScript& genesisOutputScript, uint32_t nTime, uint32_t nNonce, uint32_t nBits, int32_t nVersion, const CAmount& genesisReward)
{
    CMutableTransaction txNew;
    txNew.nVersion = 1;
    txNew.vin.resize(1);
    txNew.vout.resize(1);
    txNew.vin[0].scriptSig = CScript() << 486604799 << CScriptNum(4) << std::vector<unsigned char>((const unsigned char*)pszTimestamp, (const unsigned char*)pszTimestamp + strlen(pszTimestamp));
    txNew.vout[0].nValue = genesisReward;
    txNew.vout[0].scriptPubKey = genesisOutputScript;

    CBlock genesis;
    genesis.nTime    = nTime;
    genesis.nBits    = nBits;
    genesis.nNonce   = nNonce;
    genesis.nVersion = nVersion;
    genesis.vtx.push_back(MakeTransactionRef(std::move(txNew)));
    genesis.hashPrevBlock.SetNull();
    genesis.hashMerkleRoot = BlockMerkleRoot(genesis);
    return genesis;
}

static CBlock CreateGenesisBlock(uint32_t nTime, uint32_t nNonce, uint32_t nBits, int32_t nVersion, const CAmount& genesisReward)
{
    const char* pszTimestamp = "The Times 06/May/2026 AI agents are now coding their own blockchains";
    const CScript genesisOutputScript = CScript() << ParseHex("04678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5f") << OP_CHECKSIG;
    return CreateGenesisBlock(pszTimestamp, genesisOutputScript, nTime, nNonce, nBits, nVersion, genesisReward);
}

class CMainParams : public CChainParams {
public:
    CMainParams() {
        m_chain_type = ChainType::MAIN;
        consensus.nSubsidyHalvingInterval = 1051200;
        consensus.BIP34Height = 1;
        consensus.BIP34Hash = uint256();
        consensus.BIP65Height = 1;
        consensus.BIP66Height = 1;
        consensus.CSVHeight = 1;
        consensus.SegwitHeight = 1;
        consensus.MinBIP9WarningHeight = 0;
        consensus.powLimit = uint256S("00000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        consensus.nPowTargetTimespan = 24 * 60 * 60;
        consensus.nPowTargetSpacing = 90;
        consensus.fPowAllowMinDifficultyBlocks = false;
        consensus.fPowNoRetargeting = false;

        pchMessageStart[0] = 0x4b;
        pchMessageStart[1] = 0x50;
        pchMessageStart[2] = 0x43;
        pchMessageStart[3] = 0x01;
        nDefaultPort = 12130;
        
        genesis = CreateGenesisBlock(1715000000, 0, 0x207fffff, 1, 161800000 * 100000000LL);
        consensus.hashGenesisBlock = genesis.GetHash();

        vSeeds.clear();
        base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,45); // Starts with 'K'
        base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,107);
        base58Prefixes[SECRET_KEY] =     std::vector<unsigned char>(1,128);
        base58Prefixes[EXT_PUBLIC_KEY] = {0x04, 0x88, 0xB2, 0x1E};
        base58Prefixes[EXT_SECRET_KEY] = {0x04, 0x88, 0xAD, 0xE4};

        bech32_hrp = "kpc"; // Address starts with 'kpc'
        
        fDefaultConsistencyChecks = false;
        m_is_mockable_chain = false;
        
        checkpointData = {
            {
                {0, uint256S("0x00")},
            }
        };
        
        chainTxData = ChainTxData{1715000000, 0, 0};
    }
};

class CTestNetParams : public CChainParams {
public:
    CTestNetParams() {
        m_chain_type = ChainType::TESTNET;
        consensus.powLimit = uint256S("00000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        nDefaultPort = 22130;
        genesis = CreateGenesisBlock(1715000000, 0, 0x207fffff, 1, 161800000 * 100000000LL);
        consensus.hashGenesisBlock = genesis.GetHash();
        bech32_hrp = "tkpc";
        checkpointData = { { {0, uint256S("0x00")}, } };
    }
};

class CRegTestParams : public CChainParams {
public:
    explicit CRegTestParams(const RegTestOptions& opts) {
        m_chain_type = ChainType::REGTEST;
        consensus.powLimit = uint256S("7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        nDefaultPort = 18444;
        genesis = CreateGenesisBlock(1715000000, 0, 0x207fffff, 1, 161800000 * 100000000LL);
        consensus.hashGenesisBlock = genesis.GetHash();
        bech32_hrp = "regkpc";
        checkpointData = { { {0, uint256S("0x00")}, } };
    }
};

std::unique_ptr<const CChainParams> CChainParams::SigNet(const SigNetOptions& options) { return std::make_unique<const CMainParams>(); }
std::unique_ptr<const CChainParams> CChainParams::RegTest(const RegTestOptions& options) { return std::make_unique<const CRegTestParams>(options); }
std::unique_ptr<const CChainParams> CChainParams::Main() { return std::make_unique<const CMainParams>(); }
std::unique_ptr<const CChainParams> CChainParams::TestNet() { return std::make_unique<const CTestNetParams>(); }
