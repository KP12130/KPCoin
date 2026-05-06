#!/bin/bash
# ============================================
# KPCoin Build Environment Setup
# Run this inside WSL/Ubuntu
# ============================================

set -e

echo "=========================================="
echo "  KPCoin Build Environment Setup"
echo "=========================================="

# Update system
echo "[1/5] Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Bitcoin Core build dependencies
echo "[2/5] Installing build dependencies..."
sudo apt-get install -y \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    bsdmainutils \
    python3 \
    libevent-dev \
    libboost-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libsqlite3-dev \
    libminiupnpc-dev \
    libnatpmp-dev \
    libzmq3-dev \
    systemtap-sdt-dev \
    libqrencode-dev \
    libdb-dev \
    libdb++-dev \
    libssl-dev \
    cmake \
    git \
    curl \
    wget

# Clone Bitcoin Core (v27.0 - stable release)
echo "[3/5] Cloning Bitcoin Core source..."
KPCOIN_DIR="$HOME/kpcoin"
if [ -d "$KPCOIN_DIR" ]; then
    echo "Directory $KPCOIN_DIR already exists, skipping clone."
else
    git clone --depth 1 --branch v27.0 https://github.com/bitcoin/bitcoin.git "$KPCOIN_DIR"
fi

# Clone RandomX library
echo "[4/5] Cloning RandomX library..."
RANDOMX_DIR="$KPCOIN_DIR/src/randomx"
if [ -d "$RANDOMX_DIR" ]; then
    echo "RandomX already cloned, skipping."
else
    git clone --depth 1 https://github.com/tevador/RandomX.git "$RANDOMX_DIR"
fi

# Build RandomX as a static library
echo "[5/5] Building RandomX library..."
cd "$RANDOMX_DIR"
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DARCH=native ..
make -j$(nproc)

echo ""
echo "=========================================="
echo "  Build environment ready!"
echo "  Bitcoin Core source: $KPCOIN_DIR"
echo "  RandomX library: $RANDOMX_DIR"
echo "=========================================="
echo ""
echo "Next step: Run the modify_source.sh script"
