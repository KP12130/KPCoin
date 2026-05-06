import hashlib
import struct

def double_sha256(data):
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def calculate_merkle_root(pszTimestamp, reward_coins, pubkey_hex):
    # Reward in Satoshis (CAmount)
    reward_sats = reward_coins * 100000000
    
    # Transaction Version (1)
    tx_version = struct.pack("<I", 1)
    
    # Inputs (1)
    tx_vin_count = b"\x01"
    
    # PrevOut (Null: 32 bytes of 0, 0xffffffff)
    prevout_hash = b"\x00" * 32
    prevout_index = struct.pack("<I", 0xffffffff)
    
    # ScriptSig
    # nBits (486604799) encoded as 4 bytes
    # nNonce (4) encoded as 1 byte
    # pszTimestamp
    script_sig = struct.pack("<I", 486604799) + b"\x01\x04" + struct.pack("B", len(pszTimestamp)) + pszTimestamp.encode()
    script_sig_len = struct.pack("B", len(script_sig))
    
    tx_vin = prevout_hash + prevout_index + script_sig_len + script_sig + b"\xff\xff\xff\xff"
    
    # Outputs (1)
    tx_vout_count = b"\x01"
    
    # Value (8 bytes)
    tx_value = struct.pack("<Q", reward_sats)
    
    # ScriptPubKey (OP_PUSH bytes + PubKey + OP_CHECKSIG)
    pubkey_bytes = bytes.fromhex(pubkey_hex)
    script_pubkey = struct.pack("B", len(pubkey_bytes)) + pubkey_bytes + b"\xac" # AC is OP_CHECKSIG
    script_pubkey_len = struct.pack("B", len(script_pubkey))
    
    tx_vout = tx_value + script_pubkey_len + script_pubkey
    
    # Locktime (0)
    tx_locktime = struct.pack("<I", 0)
    
    # Full Transaction
    tx = tx_version + tx_vin_count + tx_vin + tx_vout_count + tx_vout + tx_locktime
    
    # Transaction Hash (Double SHA256)
    tx_hash = double_sha256(tx)
    
    # For a block with 1 tx, Merkle Root = Tx Hash
    return tx_hash[::-1].hex() # Reverse for big-endian display

pszTimestamp = "The Times 06/May/2026 AI agents are now coding their own blockchains"
reward_coins = 161800000
pubkey_hex = "04678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5f"

merkle_root = calculate_merkle_root(pszTimestamp, reward_coins, pubkey_hex)
print(f"Merkle Root: {merkle_root}")
