#!/bin/bash
# Aggressive text replacement for build system files
cd ~/kpcoin

echo "Replacing 'bitcoin-config.h' with 'kpcoin-config.h'..."
find . -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.am" -o -name "*.ac" -o -name "*.py" -o -name "Makefile" -o -name "configure" \) | xargs sed -i 's/bitcoin-config.h/kpcoin-config.h/g'

echo "Replacing 'bitcoin-config.h.in' with 'kpcoin-config.h.in'..."
find . -type f \( -name "*.cpp" -o -name "*.h" -o -name "*.am" -o -name "*.ac" -o -name "*.py" -o -name "Makefile" -o -name "configure" \) | xargs sed -i 's/bitcoin-config.h.in/kpcoin-config.h.in/g'

# Also check for other missed occurrences like AC_INIT
sed -i 's/AC_INIT(\[Bitcoin Core\]/AC_INIT([KPCoin Core]/g' configure.ac
sed -i 's/\[bitcoin\]/\[kpcoin\]/g' configure.ac

echo "Running autogen.sh again to regenerate build system..."
./autogen.sh

echo "Running configure again..."
./configure --without-gui --disable-tests --disable-bench --with-incompatible-bdb CXXFLAGS="-I/home/kp/kpcoin/src/randomx/src" LDFLAGS="-L/home/kp/kpcoin/src/randomx/build" LIBS="-lrandomx -lpthread"

echo "Done."
