#!/bin/bash
# Pre-create all .Tpo files that make expects to mv
# This is needed because libtool with -static doesn't write .Tpo dep files

cd ~/kpcoin/src

# Find all .Plo stubs and create corresponding .Tpo files
find . -name '*.Plo' | while read plo; do
    dir=$(dirname "$plo")
    base=$(basename "$plo" .Plo)
    tpo="$dir/${base}.Tpo"
    if [ ! -f "$tpo" ]; then
        touch "$tpo"
    fi
done

echo "All .Tpo files pre-created."
