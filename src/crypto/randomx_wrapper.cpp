// Copyright (c) 2024-2026 KPCoin Developers
// Distributed under the MIT software license.

#include <crypto/randomx_wrapper.h>
#include <randomx.h>
#include <util/strencodings.h>
#include <hash.h>
#include <logging.h>

#include <cstring>
#include <stdexcept>

RandomXWrapper::RandomXWrapper()
    : m_cache(nullptr),
      m_dataset(nullptr),
      m_vm(nullptr),
      m_isMiningMode(false)
{
}

RandomXWrapper::~RandomXWrapper()
{
    Cleanup();
}

RandomXWrapper& RandomXWrapper::GetInstance()
{
    static RandomXWrapper instance;
    return instance;
}

int RandomXWrapper::GetKeyBlockHeight(int nHeight)
{
    // For the first RANDOMX_KEY_INTERVAL blocks, use the genesis key
    if (nHeight < RANDOMX_KEY_INTERVAL) {
        return -1; // Signal to use genesis key
    }

    // Key changes every RANDOMX_KEY_INTERVAL blocks
    // Use the block hash from (current_epoch_start - 1) as the key
    int epochStart = nHeight - (nHeight % RANDOMX_KEY_INTERVAL);
    return epochStart - 1;
}

bool RandomXWrapper::NeedsKeyChange(const unsigned char* newKey, size_t keyLen)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_currentKey.size() != keyLen) return true;
    return memcmp(m_currentKey.data(), newKey, keyLen) != 0;
}

void RandomXWrapper::InitCache(const unsigned char* key, size_t keyLen)
{
    if (m_cache) {
        randomx_release_cache(m_cache);
        m_cache = nullptr;
    }

    m_cache = randomx_alloc_cache(RANDOMX_FLAG_DEFAULT);
    if (!m_cache) {
        throw std::runtime_error("RandomX: Failed to allocate cache");
    }

    randomx_init_cache(m_cache, key, keyLen);

    // Store current key
    m_currentKey.assign(key, key + keyLen);

    LogPrintf("RandomX: Cache initialized with key of %d bytes\n", keyLen);
}

void RandomXWrapper::InitDataset()
{
    if (m_dataset) {
        randomx_release_dataset(m_dataset);
        m_dataset = nullptr;
    }

    m_dataset = randomx_alloc_dataset(RANDOMX_FLAG_DEFAULT);
    if (!m_dataset) {
        throw std::runtime_error("RandomX: Failed to allocate dataset");
    }

    // Initialize dataset from cache
    unsigned long datasetItemCount = randomx_dataset_item_count();
    randomx_init_dataset(m_dataset, m_cache, 0, datasetItemCount);

    LogPrintf("RandomX: Full dataset initialized (%lu items)\n", datasetItemCount);
}

void RandomXWrapper::InitVM(bool fullMem)
{
    DestroyVM();

    randomx_flags flags = RANDOMX_FLAG_DEFAULT;

    // Try to use hardware AES if available
    flags |= RANDOMX_FLAG_HARD_AES;

    // Try to use large pages for better performance
    flags |= RANDOMX_FLAG_LARGE_PAGES;

    if (fullMem && m_dataset) {
        flags |= RANDOMX_FLAG_DEFAULT;
        m_vm = randomx_create_vm(flags, m_cache, m_dataset);
        if (!m_vm) {
            // Retry without large pages
            flags &= ~RANDOMX_FLAG_LARGE_PAGES;
            m_vm = randomx_create_vm(flags, m_cache, m_dataset);
        }
    } else {
        m_vm = randomx_create_vm(flags, m_cache, nullptr);
        if (!m_vm) {
            // Retry without large pages and hardware AES
            flags = RANDOMX_FLAG_DEFAULT;
            m_vm = randomx_create_vm(flags, m_cache, nullptr);
        }
    }

    if (!m_vm) {
        throw std::runtime_error("RandomX: Failed to create VM");
    }

    LogPrintf("RandomX: VM created (mode=%s, flags=%d)\n",
              fullMem ? "mining" : "verify", flags);
}

void RandomXWrapper::DestroyVM()
{
    if (m_vm) {
        randomx_destroy_vm(m_vm);
        m_vm = nullptr;
    }
}

void RandomXWrapper::InitMiningMode(const unsigned char* key, size_t keyLen)
{
    std::lock_guard<std::mutex> lock(m_mutex);

    LogPrintf("RandomX: Initializing mining mode...\n");

    InitCache(key, keyLen);
    InitDataset();
    InitVM(true);
    m_isMiningMode = true;

    LogPrintf("RandomX: Mining mode ready (full dataset in RAM)\n");
}

void RandomXWrapper::InitVerifyMode(const unsigned char* key, size_t keyLen)
{
    std::lock_guard<std::mutex> lock(m_mutex);

    LogPrintf("RandomX: Initializing verification mode...\n");

    InitCache(key, keyLen);
    InitVM(false);
    m_isMiningMode = false;

    LogPrintf("RandomX: Verification mode ready (cache only)\n");
}

uint256 RandomXWrapper::Hash(const unsigned char* input, size_t inputLen,
                             const unsigned char* key, size_t keyLen)
{
    std::lock_guard<std::mutex> lock(m_mutex);

    // Check if we need to reinitialize with a new key
    if (!m_vm || m_currentKey.size() != keyLen ||
        memcmp(m_currentKey.data(), key, keyLen) != 0) {

        InitCache(key, keyLen);

        if (m_isMiningMode) {
            InitDataset();
            InitVM(true);
        } else {
            InitVM(false);
        }
    }

    // Compute the RandomX hash
    unsigned char hash[RANDOMX_HASH_SIZE]; // 32 bytes
    randomx_calculate_hash(m_vm, input, inputLen, hash);

    // Convert to uint256
    uint256 result;
    memcpy(result.begin(), hash, 32);

    return result;
}

uint256 RandomXWrapper::LightHash(const unsigned char* input, size_t inputLen,
                                  const unsigned char* key, size_t keyLen)
{
    // Force verification (light) mode for this hash
    std::lock_guard<std::mutex> lock(m_mutex);

    if (!m_vm || m_currentKey.size() != keyLen ||
        memcmp(m_currentKey.data(), key, keyLen) != 0) {
        InitCache(key, keyLen);
        InitVM(false);
    }

    unsigned char hash[RANDOMX_HASH_SIZE];
    randomx_calculate_hash(m_vm, input, inputLen, hash);

    uint256 result;
    memcpy(result.begin(), hash, 32);

    return result;
}

void RandomXWrapper::Cleanup()
{
    std::lock_guard<std::mutex> lock(m_mutex);

    DestroyVM();

    if (m_dataset) {
        randomx_release_dataset(m_dataset);
        m_dataset = nullptr;
    }

    if (m_cache) {
        randomx_release_cache(m_cache);
        m_cache = nullptr;
    }

    m_currentKey.clear();
    m_isMiningMode = false;

    LogPrintf("RandomX: All resources released\n");
}
