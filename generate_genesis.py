#!/usr/bin/env python3
"""
KPCoin Genesis Block Generator

Generates the genesis block for the KPCoin blockchain.
This creates the initial block with the 161.8M KPC pre-mine
and computes a valid proof-of-work hash.

Usage: python3 generate_genesis.py
"""

import hashlib
import struct
import time
import sys
import os

# ============================================
# KPCoin Genesis Block Parameters
# ============================================

COIN = 100_000_000  # 1 KPC = 100,000,000 satoshis (same as Bitcoin)

# Pre-mine: 161,800,000 KPC
PREMINE_AMOUNT = 161_800_000 * COIN

# Genesis block timestamp
GENESIS_TIMESTAMP = int(time.time())

# Genesis block message (encoded in coinbase, like Bitcoin's famous message)
GENESIS_MESSAGE = b"KPCoin Genesis - The Peoples Coin - 2026"

# Initial difficulty (very low for genesis mining)
# This is nBits in compact format. 0x1e0ffff0 is a common starting point
# for altcoins (similar to Litecoin's genesis difficulty)
GENESIS_NBITS = 0x1e0ffff0

# Block version
BLOCK_VERSION = 1

# Pre-mine recipient address (will be replaced with actual pubkey)
# For now, generate a keypair
GENESIS_PUBKEY = "04678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5f"


def sha256(data):
    """Single SHA-256 hash."""
    return hashlib.sha256(data).digest()


def sha256d(data):
    """Double SHA-256 hash (Bitcoin standard)."""
    return sha256(sha256(data))


def uint256_to_hex(h):
    """Convert 32-byte hash to hex string (little-endian display)."""
    return h[::-1].hex()


def compact_size(n):
    """Encode a compact size integer."""
    if n < 0xfd:
        return struct.pack('<B', n)
    elif n <= 0xffff:
        return struct.pack('<BH', 0xfd, n)
    elif n <= 0xffffffff:
        return struct.pack('<BI', 0xfe, n)
    else:
        return struct.pack('<BQ', 0xff, n)


def create_coinbase_script(message):
    """Create the coinbase input script (scriptSig)."""
    # Bitcoin genesis format: OP_PUSH(nbits) + OP_PUSH(extra_nonce) + message
    nbits_bytes = struct.pack('<I', GENESIS_NBITS)
    extra_nonce = struct.pack('<B', 4)  # Extra nonce

    script = b''
    script += bytes([len(nbits_bytes)]) + nbits_bytes  # Push nBits
    script += bytes([len(extra_nonce)]) + extra_nonce   # Push extra nonce
    script += bytes([len(message)]) + message            # Push message

    return script


def create_pubkey_script(pubkey_hex):
    """Create P2PK output script: <pubkey> OP_CHECKSIG."""
    pubkey_bytes = bytes.fromhex(pubkey_hex)
    script = bytes([len(pubkey_bytes)]) + pubkey_bytes + bytes([0xac])  # OP_CHECKSIG
    return script


def create_coinbase_transaction(premine_amount, message, pubkey_hex):
    """Create the coinbase transaction for the genesis block."""
    tx = b''

    # Version (4 bytes, little-endian)
    tx += struct.pack('<I', 1)

    # Number of inputs (1)
    tx += compact_size(1)

    # Input: Coinbase (prev_hash = 0, prev_index = 0xffffffff)
    tx += b'\x00' * 32                    # Previous tx hash (null for coinbase)
    tx += struct.pack('<I', 0xffffffff)   # Previous output index
    coinbase_script = create_coinbase_script(message)
    tx += compact_size(len(coinbase_script))
    tx += coinbase_script
    tx += struct.pack('<I', 0xffffffff)   # Sequence

    # Number of outputs (1)
    tx += compact_size(1)

    # Output: Pre-mine amount to pubkey
    tx += struct.pack('<q', premine_amount)  # Amount (8 bytes, little-endian)
    pubkey_script = create_pubkey_script(pubkey_hex)
    tx += compact_size(len(pubkey_script))
    tx += pubkey_script

    # Lock time
    tx += struct.pack('<I', 0)

    return tx


def compute_merkle_root(txids):
    """Compute the merkle root from a list of transaction IDs."""
    if len(txids) == 0:
        return b'\x00' * 32

    hashes = list(txids)

    while len(hashes) > 1:
        if len(hashes) % 2 != 0:
            hashes.append(hashes[-1])  # Duplicate last hash if odd

        new_hashes = []
        for i in range(0, len(hashes), 2):
            new_hashes.append(sha256d(hashes[i] + hashes[i + 1]))
        hashes = new_hashes

    return hashes[0]


def serialize_block_header(version, prev_hash, merkle_root, timestamp, nbits, nonce):
    """Serialize a block header (80 bytes)."""
    header = b''
    header += struct.pack('<I', version)       # Version (4 bytes)
    header += prev_hash                         # Previous block hash (32 bytes)
    header += merkle_root                       # Merkle root (32 bytes)
    header += struct.pack('<I', timestamp)      # Timestamp (4 bytes)
    header += struct.pack('<I', nbits)          # nBits / difficulty target (4 bytes)
    header += struct.pack('<I', nonce)          # Nonce (4 bytes)
    return header


def nbits_to_target(nbits):
    """Convert compact nBits to full 256-bit target."""
    exponent = nbits >> 24
    mantissa = nbits & 0x7fffff
    if exponent <= 3:
        mantissa >>= 8 * (3 - exponent)
        target = mantissa
    else:
        target = mantissa << (8 * (exponent - 3))
    return target


def mine_genesis_block(version, prev_hash, merkle_root, timestamp, nbits):
    """
    Mine the genesis block by finding a valid nonce.
    Uses SHA-256d for genesis block mining (RandomX needs a key from
    a previous block, so genesis uses SHA-256d as a bootstrap).
    """
    target = nbits_to_target(nbits)
    print(f"\n  Target: {target:064x}")
    print(f"  Mining genesis block (SHA-256d for genesis, RandomX for all others)...")
    print(f"  This may take a few seconds to minutes...\n")

    nonce = 0
    start_time = time.time()
    last_report = start_time

    while nonce < 0xffffffff:
        header = serialize_block_header(version, prev_hash, merkle_root,
                                        timestamp, nbits, nonce)
        hash_result = sha256d(header)

        # Convert to integer (little-endian)
        hash_int = int.from_bytes(hash_result, 'little')

        if hash_int <= target:
            elapsed = time.time() - start_time
            hashrate = nonce / elapsed if elapsed > 0 else 0
            print(f"  ✅ Genesis block found!")
            print(f"  Nonce: {nonce}")
            print(f"  Hash:  {uint256_to_hex(hash_result)}")
            print(f"  Time:  {elapsed:.2f} seconds")
            print(f"  Rate:  {hashrate:.0f} H/s")
            return nonce, hash_result

        nonce += 1

        # Progress report every 5 seconds
        now = time.time()
        if now - last_report >= 5:
            elapsed = now - start_time
            hashrate = nonce / elapsed if elapsed > 0 else 0
            print(f"  ... {nonce:,} nonces tried ({hashrate:.0f} H/s)")
            last_report = now

    raise Exception("Failed to find valid nonce for genesis block!")


def generate_genesis():
    """Generate the complete KPCoin genesis block."""
    print("=" * 60)
    print("  KPCoin Genesis Block Generator")
    print("=" * 60)
    print()
    print(f"  Coin:        KPCoin (KPC)")
    print(f"  Pre-mine:    {PREMINE_AMOUNT // COIN:,} KPC")
    print(f"  Message:     {GENESIS_MESSAGE.decode()}")
    print(f"  Timestamp:   {GENESIS_TIMESTAMP}")
    print(f"  nBits:       0x{GENESIS_NBITS:08x}")

    # Create coinbase transaction
    coinbase_tx = create_coinbase_transaction(
        PREMINE_AMOUNT, GENESIS_MESSAGE, GENESIS_PUBKEY
    )
    coinbase_txid = sha256d(coinbase_tx)

    print(f"\n  Coinbase TX:  {uint256_to_hex(coinbase_txid)}")
    print(f"  Coinbase hex: {coinbase_tx.hex()}")

    # Compute merkle root (single tx = txid)
    merkle_root = coinbase_txid
    print(f"  Merkle root:  {uint256_to_hex(merkle_root)}")

    # Previous block hash (all zeros for genesis)
    prev_hash = b'\x00' * 32

    # Mine the genesis block
    nonce, block_hash = mine_genesis_block(
        BLOCK_VERSION, prev_hash, merkle_root,
        GENESIS_TIMESTAMP, GENESIS_NBITS
    )

    # Generate the complete header
    header = serialize_block_header(
        BLOCK_VERSION, prev_hash, merkle_root,
        GENESIS_TIMESTAMP, GENESIS_NBITS, nonce
    )

    print()
    print("=" * 60)
    print("  GENESIS BLOCK DATA")
    print("=" * 60)
    print()
    print(f"  Block Hash:     {uint256_to_hex(block_hash)}")
    print(f"  Merkle Root:    {uint256_to_hex(merkle_root)}")
    print(f"  Timestamp:      {GENESIS_TIMESTAMP}")
    print(f"  nBits:          0x{GENESIS_NBITS:08x}")
    print(f"  Nonce:          {nonce}")
    print(f"  Header (hex):   {header.hex()}")
    print()

    # Generate C++ code for chainparams.cpp
    print("=" * 60)
    print("  C++ CODE FOR chainparams.cpp")
    print("=" * 60)
    print()

    cpp_code = f'''
// KPCoin Genesis Block
// Message: "{GENESIS_MESSAGE.decode()}"
// Pre-mine: {PREMINE_AMOUNT // COIN:,} KPC

genesis = CreateGenesisBlock(
    {GENESIS_TIMESTAMP},         // nTime
    {nonce},                     // nNonce
    0x{GENESIS_NBITS:08x},      // nBits
    {BLOCK_VERSION},             // nVersion
    {PREMINE_AMOUNT // COIN} * COIN  // genesisReward (pre-mine)
);

consensus.hashGenesisBlock = genesis.GetHash();
assert(consensus.hashGenesisBlock == uint256S("0x{uint256_to_hex(block_hash)}"));
assert(genesis.hashMerkleRoot == uint256S("0x{uint256_to_hex(merkle_root)}"));
'''

    print(cpp_code)

    # Save to file
    output_dir = os.path.dirname(os.path.abspath(__file__))
    output_file = os.path.join(output_dir, "genesis_block_data.txt")
    with open(output_file, 'w') as f:
        f.write("KPCoin Genesis Block Data\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Block Hash:     {uint256_to_hex(block_hash)}\n")
        f.write(f"Merkle Root:    {uint256_to_hex(merkle_root)}\n")
        f.write(f"Timestamp:      {GENESIS_TIMESTAMP}\n")
        f.write(f"nBits:          0x{GENESIS_NBITS:08x}\n")
        f.write(f"Nonce:          {nonce}\n")
        f.write(f"Coinbase TX:    {coinbase_tx.hex()}\n")
        f.write(f"Header (hex):   {header.hex()}\n")
        f.write(f"\nC++ Code:\n{cpp_code}\n")

    print(f"\n  Genesis data saved to: {output_file}")
    print()

    return {
        'hash': uint256_to_hex(block_hash),
        'merkle_root': uint256_to_hex(merkle_root),
        'timestamp': GENESIS_TIMESTAMP,
        'nbits': GENESIS_NBITS,
        'nonce': nonce,
        'coinbase_tx': coinbase_tx.hex(),
        'header': header.hex(),
    }


if __name__ == '__main__':
    genesis_data = generate_genesis()
