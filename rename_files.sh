#!/bin/bash
# Rename bitcoin source files to kpcoin
cd ~/kpcoin/src

mv bitcoind.cpp kpcoind.cpp 2>/dev/null
mv bitcoin-cli.cpp kpcoin-cli.cpp 2>/dev/null
mv bitcoin-tx.cpp kpcoin-tx.cpp 2>/dev/null
mv bitcoin-util.cpp kpcoin-util.cpp 2>/dev/null
mv bitcoin-wallet.cpp kpcoin-wallet.cpp 2>/dev/null
mv bitcoin-chainstate.cpp kpcoin-chainstate.cpp 2>/dev/null

# Also fix includes inside renamed files
sed -i 's/#include <bitcoind.h>/#include <kpcoind.h>/g' kpcoind.cpp 2>/dev/null

# Rename header files if they exist
mv bitcoind.h kpcoind.h 2>/dev/null

echo "Renamed files:"
ls -la kpcoin*.cpp
