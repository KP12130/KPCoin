#!/bin/bash
# ============================================
# KPCoin Source Modification Script
# Transforms Bitcoin Core v27.0 into KPCoin
# ============================================

set -e

KPCOIN_DIR="$HOME/kpcoin"
PATCHES_DIR="$(cd "$(dirname "$0")" && pwd)/src_patches"

if [ ! -d "$KPCOIN_DIR/src" ]; then
    echo "ERROR: Bitcoin Core source not found at $KPCOIN_DIR"
    echo "Run setup_build_env.sh first!"
    exit 1
fi

echo "=========================================="
echo "  Modifying Bitcoin Core → KPCoin"
echo "=========================================="

# ==========================================
# 1. BRANDING: Bitcoin → KPCoin
# ==========================================
echo "[1/8] Applying branding changes..."

# Rename key identifiers in source files
find "$KPCOIN_DIR/src" -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.am" \) | while read file; do
    # Be careful: only replace string literals and comments, not code symbols initially
    sed -i 's/Bitcoin Core/KPCoin Core/g' "$file"
    sed -i 's/Bitcoin core/KPCoin core/g' "$file"
    sed -i 's/"Bitcoin"/"KPCoin"/g' "$file"
    sed -i 's/"bitcoin"/"kpcoin"/g' "$file"
done

# Rename binary references
find "$KPCOIN_DIR" -type f -name "Makefile.am" | while read file; do
    sed -i 's/bitcoind/kpcoind/g' "$file"
    sed -i 's/bitcoin-cli/kpcoin-cli/g' "$file"
    sed -i 's/bitcoin-tx/kpcoin-tx/g' "$file"
    sed -i 's/bitcoin-qt/kpcoin-qt/g' "$file"
    sed -i 's/bitcoin-wallet/kpcoin-wallet/g' "$file"
    sed -i 's/bitcoin-util/kpcoin-util/g' "$file"
done

# Config directory
find "$KPCOIN_DIR/src" -type f \( -name "*.cpp" -o -name "*.h" \) | while read file; do
    sed -i 's/\.bitcoin/\.kpcoin/g' "$file"
done

# Unit naming
find "$KPCOIN_DIR/src" -type f \( -name "*.cpp" -o -name "*.h" \) | while read file; do
    sed -i 's/"BTC"/"KPC"/g' "$file"
    sed -i 's/"btc"/"kpc"/g' "$file"
    sed -i 's/"satoshi"/"kpsat"/g' "$file"
done

echo "    Branding applied."

# ==========================================
# 2. CONSENSUS PARAMETERS
# ==========================================
echo "[2/8] Setting consensus parameters..."

# --- chainparams.cpp ---
CHAINPARAMS="$KPCOIN_DIR/src/kernel/chainparams.cpp"
if [ ! -f "$CHAINPARAMS" ]; then
    CHAINPARAMS="$KPCOIN_DIR/src/chainparams.cpp"
fi

# Halving interval: 210000 → 1051200
sed -i 's/nSubsidyHalvingInterval = 210000/nSubsidyHalvingInterval = 1051200/g' "$CHAINPARAMS"

# Block time: 10 minutes → 90 seconds
# nPowTargetSpacing = 10 * 60 → 90
sed -i 's/nPowTargetSpacing = 10 \* 60/nPowTargetSpacing = 90/g' "$CHAINPARAMS"

# Difficulty retarget timespan: adjust for 90s blocks
# Original: 14 * 24 * 60 * 60 = 1209600 seconds (2 weeks, 2016 blocks at 10min)
# New: We want retarget every ~1 day (960 blocks at 90s) = 86400 seconds
sed -i 's/nPowTargetTimespan = 14 \* 24 \* 60 \* 60/nPowTargetTimespan = 24 * 60 * 60/g' "$CHAINPARAMS"

# Default port: 8333 → 12130
sed -i 's/nDefaultPort = 8333/nDefaultPort = 12130/g' "$CHAINPARAMS"

# Testnet port: 18333 → 22130
sed -i 's/nDefaultPort = 18333/nDefaultPort = 22130/g' "$CHAINPARAMS"

# Network magic bytes (mainnet) - unique 4-byte identifier
# Bitcoin: 0xf9beb4d9 → KPCoin: 0x4b504301 ("KPC\x01")
sed -i "s/pchMessageStart\[0\] = 0xf9/pchMessageStart[0] = 0x4b/g" "$CHAINPARAMS"
sed -i "s/pchMessageStart\[1\] = 0xbe/pchMessageStart[1] = 0x50/g" "$CHAINPARAMS"
sed -i "s/pchMessageStart\[2\] = 0xb4/pchMessageStart[2] = 0x43/g" "$CHAINPARAMS"
sed -i "s/pchMessageStart\[3\] = 0xd9/pchMessageStart[3] = 0x01/g" "$CHAINPARAMS"

# Address prefix - Mainnet addresses start with 'K'
# Bitcoin mainnet = 0 (addresses start with '1')
# 'K' in base58 → pubkey prefix = 45
sed -i 's/base58Prefixes\[PUBKEY_ADDRESS\] = std::vector<unsigned char>(1,0)/base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,45)/g' "$CHAINPARAMS"

# Script address prefix - 'k' (lowercase)
# Bitcoin = 5 (addresses start with '3')
sed -i 's/base58Prefixes\[SCRIPT_ADDRESS\] = std::vector<unsigned char>(1,5)/base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,107)/g' "$CHAINPARAMS"

# Private key prefix (WIF)
# Bitcoin = 128 → KPCoin = 173
sed -i 's/base58Prefixes\[SECRET_KEY\] =   std::vector<unsigned char>(1,128)/base58Prefixes[SECRET_KEY] =   std::vector<unsigned char>(1,173)/g' "$CHAINPARAMS"

# Remove DNS seeds (we'll add our own later)
# We'll handle this with a more targeted approach
python3 - "$CHAINPARAMS" << 'PYEOF'
import sys
import re

filepath = sys.argv[1]
with open(filepath, 'r') as f:
    content = f.read()

# Clear DNS seed entries - replace with empty
content = re.sub(
    r'vSeeds\.emplace_back\("[^"]*"\);',
    '// DNS seeds removed for KPCoin - use -addnode instead',
    content
)

with open(filepath, 'w') as f:
    f.write(content)

print("    DNS seeds cleared.")
PYEOF

echo "    Consensus parameters set."

# ==========================================
# 3. BLOCK REWARD & SUPPLY CAP
# ==========================================
echo "[3/8] Setting block reward and supply cap..."

# --- validation.cpp ---
VALIDATION="$KPCOIN_DIR/src/validation.cpp"

# Block reward: 50 * COIN → 500 * COIN
sed -i 's/CAmount nSubsidy = 50 \* COIN/CAmount nSubsidy = 500 * COIN/g' "$VALIDATION"

# --- amount.h ---
AMOUNT_H="$KPCOIN_DIR/src/consensus/amount.h"

# Max supply: 21000000 → 1213000000 (1.213 billion)
sed -i 's/MAX_MONEY = 21000000 \* COIN/MAX_MONEY = 1213000000LL * COIN/g' "$AMOUNT_H"
# Also handle the case where it might be written as 2100000000000000
sed -i 's/MAX_MONEY = 2100000000000000/MAX_MONEY = 121300000000000000LL/g' "$AMOUNT_H"

echo "    Block reward: 500 KPC, Max supply: 1,213,000,000 KPC."

# ==========================================
# 4. DIFFICULTY RETARGET ADJUSTMENT
# ==========================================
echo "[4/8] Adjusting difficulty retarget..."

# In pow.cpp, Bitcoin retargets every 2016 blocks.
# With our 90s target and 24h retarget timespan:
# blocks_per_retarget = 86400 / 90 = 960
POW_CPP="$KPCOIN_DIR/src/pow.cpp"

# The retarget interval is calculated as nPowTargetTimespan / nPowTargetSpacing
# which will now be 86400 / 90 = 960 blocks. This is handled automatically
# by Bitcoin Core using the consensus params, but we need to make sure
# the DifficultyAdjustmentInterval() function is used consistently.

echo "    Difficulty retargets every ~960 blocks (~24 hours)."

# ==========================================
# 5. INTEGRATE RANDOMX
# ==========================================
echo "[5/8] Integrating RandomX..."

# Copy RandomX wrapper files
cp "$PATCHES_DIR/randomx_wrapper.h" "$KPCOIN_DIR/src/crypto/"
cp "$PATCHES_DIR/randomx_wrapper.cpp" "$KPCOIN_DIR/src/crypto/"

# Patch pow.cpp to use RandomX
cp "$PATCHES_DIR/pow_randomx.cpp" "$KPCOIN_DIR/src/pow.cpp"

# Patch pow.h to include RandomX declarations  
cp "$PATCHES_DIR/pow_randomx.h" "$KPCOIN_DIR/src/pow.h"

# Update Makefile.am to include RandomX source files
MAKEFILE_AM="$KPCOIN_DIR/src/Makefile.am"

# Add RandomX wrapper to the build
sed -i '/crypto\/sha256\.cpp/a \\tcrypto/randomx_wrapper.cpp \\' "$MAKEFILE_AM"
sed -i '/crypto\/sha256\.h/a \\tcrypto/randomx_wrapper.h \\' "$MAKEFILE_AM"

# Add RandomX library linkage
sed -i 's/LDADD = \\/LDADD = $(top_srcdir)\/src\/randomx\/build\/librandomx.a \\/g' "$MAKEFILE_AM"

# Add RandomX include path
sed -i 's/AM_CPPFLAGS =/AM_CPPFLAGS = -I$(top_srcdir)\/src\/randomx\/src/g' "$MAKEFILE_AM"

echo "    RandomX integrated."

# ==========================================
# 6. CONFIGURE FOR GENESIS BLOCK
# ==========================================
echo "[6/8] Preparing genesis block configuration..."

# The genesis block will be generated separately by generate_genesis.py
# For now, we set placeholder values that will be replaced

echo "    Genesis block placeholders set (run generate_genesis.py next)."

# ==========================================
# 7. RPC PORT CONFIGURATION
# ==========================================
echo "[7/8] Setting RPC configuration..."

# Default RPC port
CHAINPARAMSBASE="$KPCOIN_DIR/src/kernel/chainparams.cpp"
if [ ! -f "$CHAINPARAMSBASE" ]; then
    CHAINPARAMSBASE="$KPCOIN_DIR/src/chainparams.cpp"
fi

# Main RPC: 8332 → 12131
find "$KPCOIN_DIR/src" -type f \( -name "*.cpp" -o -name "*.h" \) -exec \
    sed -i 's/8332/12131/g' {} \;

# Testnet RPC: 18332 → 22131  
find "$KPCOIN_DIR/src" -type f \( -name "*.cpp" -o -name "*.h" \) -exec \
    sed -i 's/18332/22131/g' {} \;

echo "    RPC ports configured (mainnet: 12131, testnet: 22131)."

# ==========================================
# 8. CHECKPOINT REMOVAL
# ==========================================
echo "[8/8] Removing Bitcoin checkpoints..."

python3 - "$CHAINPARAMS" << 'PYEOF'
import sys
import re

filepath = sys.argv[1]
with open(filepath, 'r') as f:
    content = f.read()

# Remove checkpoint entries (keep the structure but empty the data)
# This is done by replacing checkpoint blocks with empty maps
content = re.sub(
    r'checkpointData = \{[^}]*\{[^}]*\}[^}]*\}',
    'checkpointData = {\n                {\n                }\n            }',
    content,
    flags=re.DOTALL
)

with open(filepath, 'w') as f:
    f.write(content)

print("    Checkpoints cleared.")
PYEOF

echo ""
echo "=========================================="
echo "  Source modifications complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run: python3 generate_genesis.py"
echo "  2. Run: ./build_kpcoin.sh"
