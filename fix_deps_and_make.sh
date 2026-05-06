#!/bin/bash
cd ~/kpcoin/src
find . -type d | while read d; do
    mkdir -p "$d/.deps"
done
echo "All .deps dirs created."
make -j1 2>&1 | tail -30
