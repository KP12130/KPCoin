#!/bin/bash
# ============================================
# KPCoin Master Build Script
# One-click setup, modify, generate, and build
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  ██╗  ██╗██████╗  ██████╗ ██████╗ ██╗███╗   ██╗"
echo "  ██║ ██╔╝██╔══██╗██╔════╝██╔═══██╗██║████╗  ██║"
echo "  █████╔╝ ██████╔╝██║     ██║   ██║██║██╔██╗ ██║"
echo "  ██╔═██╗ ██╔═══╝ ██║     ██║   ██║██║██║╚██╗██║"
echo "  ██║  ██╗██║     ╚██████╗╚██████╔╝██║██║ ╚████║"
echo "  ╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝"
echo ""
echo "  The People's Coin - ASIC-Resistant CPU Mining"
echo "  Supply: 1,213,000,000 KPC | Block: 90s | Reward: 500 KPC"
echo ""
echo "=========================================="
echo "  STEP 1: Setting up build environment"
echo "=========================================="
bash "$SCRIPT_DIR/setup_build_env.sh"

echo ""
echo "=========================================="
echo "  STEP 2: Generating genesis block"
echo "=========================================="
cd "$SCRIPT_DIR"
python3 generate_genesis.py

echo ""
echo "=========================================="
echo "  STEP 3: Modifying Bitcoin Core → KPCoin"
echo "=========================================="
bash "$SCRIPT_DIR/modify_source.sh"

# Apply genesis block data
echo ""
echo "  Applying genesis block data to chainparams..."
if [ -f "$SCRIPT_DIR/genesis_block_data.txt" ]; then
    echo "  Genesis data found. You'll need to manually update"
    echo "  chainparams.cpp with the values from genesis_block_data.txt"
    echo "  (This step will be automated in the next version)"
fi

echo ""
echo "=========================================="
echo "  STEP 4: Building KPCoin"
echo "=========================================="
bash "$SCRIPT_DIR/build_kpcoin.sh"

echo ""
echo "=========================================="
echo "  STEP 5: Initial setup"
echo "=========================================="

# Create data directory
DATADIR="$HOME/.kpcoin"
mkdir -p "$DATADIR"

# Copy config
cp "$SCRIPT_DIR/kpcoin.conf" "$DATADIR/kpcoin.conf"

# Generate random RPC password
RPC_PASSWORD=$(openssl rand -hex 32)
sed -i "s/CHANGE_THIS_TO_A_STRONG_PASSWORD/$RPC_PASSWORD/" "$DATADIR/kpcoin.conf"

echo "  Data directory: $DATADIR"
echo "  Config file:    $DATADIR/kpcoin.conf"
echo "  RPC password:   $RPC_PASSWORD"

echo ""
echo "=========================================="
echo "  🎉 KPCoin is ready!"
echo "=========================================="
echo ""
echo "  Start your node:"
echo "    ~/kpcoin/src/kpcoind -datadir=$DATADIR -daemon"
echo ""
echo "  Get a wallet address:"
echo "    ~/kpcoin/src/kpcoin-cli -datadir=$DATADIR getnewaddress"
echo ""
echo "  Start mining:"
echo "    ~/kpcoin/src/kpcoin-cli -datadir=$DATADIR generatetoaddress 1 <address>"
echo ""
echo "  Check balance:"
echo "    ~/kpcoin/src/kpcoin-cli -datadir=$DATADIR getbalance"
echo ""
echo "  Stop node:"
echo "    ~/kpcoin/src/kpcoin-cli -datadir=$DATADIR stop"
echo ""
