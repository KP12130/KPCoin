// Copyright (c) 2024-2026 KPCoin Developers
// Distributed under the MIT software license.

#ifndef KPCOIN_CRYPTO_RANDOMX_WRAPPER_H
#define KPCOIN_CRYPTO_RANDOMX_WRAPPER_H

#include <uint256.h>
#include <vector>
#include <mutex>
#include <memory>
#include <cstdint>

// Forward declarations for RandomX types
typedef struct randomx_cache randomx_cache;
typedef struct randomx_dataset randomx_dataset;
typedef struct randomx_vm randomx_vm;

/**
 * RandomX Proof-of-Work wrapper for KPCoin.
 *
 * RandomX is a CPU-friendly, ASIC-resistant proof-of-work algorithm
 * designed by Monero developers. It uses random code execution and
 * memory-hard techniques to ensure only general-purpose CPUs can
 * efficiently compute hashes.
 *
 * Key management:
 * - The RandomX "key" changes every RANDOMX_KEY_INTERVAL blocks
 * - Key = hash of the block at height (currentHeight - (currentHeight % KEY_INTERVAL) - 1)
 * - For the genesis block (height 0), a fixed seed key is used
 */

// How often the RandomX key (cache/dataset) changes
static const int RANDOMX_KEY_INTERVAL = 2048;

// Fixed seed key for genesis block and early blocks
static const char* RANDOMX_GENESIS_KEY = "KPCoin Genesis Block 2026";

class RandomXWrapper {
public:
    // Singleton access
    static RandomXWrapper& GetInstance();

    // Delete copy/move constructors
    RandomXWrapper(const RandomXWrapper&) = delete;
    RandomXWrapper& operator=(const RandomXWrapper&) = delete;

    /**
     * Compute a RandomX hash for the given input.
     * @param input    Block header data to hash
     * @param inputLen Length of input data
     * @param key      RandomX key (derived from previous blocks)
     * @param keyLen   Length of key data
     * @return         256-bit hash result
     */
    uint256 Hash(const unsigned char* input, size_t inputLen,
                 const unsigned char* key, size_t keyLen);

    /**
     * Compute a RandomX hash using the light (verification) mode.
     * Slower but uses less memory. Good for validating blocks.
     */
    uint256 LightHash(const unsigned char* input, size_t inputLen,
                      const unsigned char* key, size_t keyLen);

    /**
     * Get the RandomX key for a given block height.
     * Returns the hash of the block that determines the key.
     * @param nHeight  Current block height
     * @return         Key block height (-1 means use genesis key)
     */
    static int GetKeyBlockHeight(int nHeight);

    /**
     * Check if we need to reinitialize the RandomX cache for a new key.
     */
    bool NeedsKeyChange(const unsigned char* newKey, size_t keyLen);

    /**
     * Initialize for mining mode (uses full dataset, ~2GB RAM, much faster).
     */
    void InitMiningMode(const unsigned char* key, size_t keyLen);

    /**
     * Initialize for verification mode (uses cache only, ~256MB RAM, slower).
     */
    void InitVerifyMode(const unsigned char* key, size_t keyLen);

    /**
     * Release all RandomX resources.
     */
    void Cleanup();

    ~RandomXWrapper();

private:
    RandomXWrapper();

    randomx_cache* m_cache;
    randomx_dataset* m_dataset;
    randomx_vm* m_vm;
    std::vector<unsigned char> m_currentKey;
    bool m_isMiningMode;
    mutable std::mutex m_mutex;

    void InitCache(const unsigned char* key, size_t keyLen);
    void InitDataset();
    void InitVM(bool fullMem);
    void DestroyVM();
};

#endif // KPCOIN_CRYPTO_RANDOMX_WRAPPER_H
