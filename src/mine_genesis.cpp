#include <iostream>
#include <vector>
#include <cstring>
#include <cstdint>
#include <iomanip>
#include <sstream>
#include <functional>

// Mock of translation function
std::function<std::string(const char*)> G_TRANSLATION_FUN = [](const char* psz) { return std::string(psz); };

class uint256 {
public:
    uint8_t data[32];
    const unsigned char* begin() const { return data; }
    std::string ToString() const {
        std::stringstream ss;
        for (int i = 31; i >= 0; i--) {
            ss << std::hex << std::setw(2) << std::setfill('0') << (int)data[i];
        }
        return ss.str();
    }
};

struct CBlockHeader_Mine {
    int32_t nVersion;
    uint8_t hashPrevBlock[32];
    uint8_t hashMerkleRoot[32];
    uint32_t nTime;
    uint32_t nBits;
    uint32_t nNonce;

    void Serialize(std::vector<unsigned char>& v) const {
        v.resize(80);
        std::memcpy(&v[0], &nVersion, 4);
        std::memcpy(&v[4], hashPrevBlock, 32);
        std::memcpy(&v[36], hashMerkleRoot, 32);
        std::memcpy(&v[68], &nTime, 4);
        std::memcpy(&v[72], &nBits, 4);
        std::memcpy(&v[76], &nNonce, 4);
    }
};

#include <mutex>
class RandomXWrapper {
public:
    static RandomXWrapper& GetInstance();
    uint256 Hash(const unsigned char* input, size_t inputLen, const unsigned char* key, size_t keyLen);
    void InitVerifyMode(const unsigned char* key, size_t keyLen);
};

void ParseHex(const char* hex, uint8_t* out) {
    for (int i = 0; i < 32; i++) {
        std::string byteString = std::string(hex + (31 - i) * 2, 2);
        out[i] = (uint8_t)std::strtol(byteString.c_str(), nullptr, 16);
    }
}

int main() {
    std::cout << "KPCoin Genesis Miner (RandomX) - Trivial Difficulty" << std::endl;

    CBlockHeader_Mine header;
    header.nVersion = 1;
    std::memset(header.hashPrevBlock, 0, 32);
    
    const char* merkleHex = "9b74a171f8e3f28379dc28846fdad742f989fcf0e49c928ecb13bb8ada2b1324";
    ParseHex(merkleHex, header.hashMerkleRoot);

    header.nTime = 1715000000;
    header.nBits = 0x217fffff; 
    
    RandomXWrapper& rx = RandomXWrapper::GetInstance();
    const char* genesisKey = "KPCoinGenesisKey";
    std::vector<unsigned char> key(genesisKey, genesisKey + strlen(genesisKey));
    rx.InitVerifyMode(key.data(), key.size());

    std::vector<unsigned char> serialized;
    std::cout << "Mining genesis with Merkle: " << merkleHex << std::endl;

    for (uint32_t n = 0; n < 100; n++) {
        header.nNonce = n;
        header.Serialize(serialized);
        
        uint256 hashResult = rx.Hash(serialized.data(), serialized.size(), key.data(), key.size());
        
        const unsigned char* d = hashResult.begin();
        // Trivial difficulty check: first bit is 0
        if (d[31] < 0x80) {
            std::cout << "\nFOUND!" << std::endl;
            std::cout << "Nonce: " << n << std::endl;
            std::cout << "Hash: " << hashResult.ToString() << std::endl;
            std::cout << "Time: " << header.nTime << std::endl;
            std::cout << "Merkle: " << merkleHex << std::endl;
            std::cout << "Bits: 0x217fffff" << std::endl;
            return 0;
        }
    }

    return 0;
}
