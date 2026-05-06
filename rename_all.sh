#!/bin/bash
# Find and rename ALL bitcoin-named source files in the source tree
cd ~/kpcoin/src

echo "Finding all bitcoin-named files..."
find . -name "bitcoin*" -type f | while read f; do
    newname=$(echo "$f" | sed 's/bitcoin/kpcoin/g')
    dir=$(dirname "$newname")
    mkdir -p "$dir"
    echo "  $f -> $newname"
    mv "$f" "$newname"
done

# Also handle 'bitcoind' named files (without hyphen)
find . -name "bitcoind*" -type f | while read f; do
    newname=$(echo "$f" | sed 's/bitcoind/kpcoind/g')
    dir=$(dirname "$newname")
    mkdir -p "$dir"
    echo "  $f -> $newname"
    mv "$f" "$newname"
done

echo ""
echo "All bitcoin-named files renamed. Checking for any remaining:"
find . -name "bitcoin*" -type f 2>/dev/null | head -20
echo "Done."
