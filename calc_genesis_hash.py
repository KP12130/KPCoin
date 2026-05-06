import hashlib
import struct

def double_sha256(data):
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

# Parameters
nVersion = 1
hashPrevBlock = b"\x00" * 32
hashMerkleRoot = bytes.fromhex("9b74a171f8e3f28379dc28846fdad742f989fcf0e49c928ecb13bb8ada2b1324")[::-1] # Reverse for little-endian
nTime = 1715000000
nBits = 0x207fffff
nNonce = 0

# Serialize Header
header = struct.pack("<i", nVersion) + hashPrevBlock + hashMerkleRoot + struct.pack("<I", nTime) + struct.pack("<I", nBits) + struct.pack("<I", nNonce)

# Calculate Hash
genesis_hash = double_sha256(header)
print(f"Genesis Hash: {genesis_hash[::-1].hex()}")
