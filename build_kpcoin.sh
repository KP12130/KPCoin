#!/bin/bash
# ============================================
# KPCoin Build Script
# Compiles the KPCoin binaries from source
# ============================================

set -e

KPCOIN_DIR="$HOME/kpcoin"
JOBS=1

if [ ! -d "$KPCOIN_DIR/src" ]; then
    echo "ERROR: KPCoin source not found at $KPCOIN_DIR"
    echo "Run setup_build_env.sh and modify_source.sh first!"
    exit 1
fi

cd "$KPCOIN_DIR"

echo "=========================================="
echo "  Building KPCoin"
echo "  Using $JOBS CPU cores"
echo "=========================================="

# Step 1: Generate build system
echo ""
echo "[1/4] Running autogen.sh..."
./autogen.sh

# Step 2: Configure
echo ""
echo "[2/4] Configuring build..."
./configure \
    --without-gui \
    --disable-tests \
    --disable-bench \
    --with-incompatible-bdb \
    CXXFLAGS="-I$KPCOIN_DIR/src/randomx/src" \
    LDFLAGS="-L$KPCOIN_DIR/src/randomx/build" \
    LIBS="-lrandomx -lpthread"

# Step 3: Compile
echo ""
echo "[3/4] Compiling (this may take 10-30 minutes)..."
make -j$JOBS

# Step 4: Verify
echo ""
echo "[4/4] Verifying build..."

if [ -f "src/kpcoind" ] || [ -f "src/bitcoind" ]; then
    echo ""
    echo "=========================================="
    echo "  ✅ BUILD SUCCESSFUL!"
    echo "=========================================="
    echo ""

    # Rename binaries if they still have bitcoin names
    if [ -f "src/bitcoind" ] && [ ! -f "src/kpcoind" ]; then
        cp src/bitcoind src/kpcoind
        cp src/bitcoin-cli src/kpcoin-cli 2>/dev/null || true
        cp src/bitcoin-tx src/kpcoin-tx 2>/dev/null || true
        cp src/bitcoin-wallet src/kpcoin-wallet 2>/dev/null || true
        echo "  Binaries renamed to kpcoin-*"
    fi

    echo ""
    echo "  Binaries built:"
    ls -la src/kpcoin* 2>/dev/null || ls -la src/bitcoin* 2>/dev/null
    echo ""
    echo "  To start your node:"
    echo "    ./src/kpcoind -daemon -datadir=\$HOME/.kpcoin"
    echo ""
    echo "  To mine:"
    echo "    ./src/kpcoin-cli -datadir=\$HOME/.kpcoin generatetoaddress 1 <your_address>"
    echo ""
    echo "  To get a new address:"
    echo "    ./src/kpcoin-cli -datadir=\$HOME/.kpcoin getnewaddress"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "  ❌ BUILD FAILED"
    echo "=========================================="
    echo "  Check the output above for errors."
    exit 1
fi
