#!/bin/bash
# Restore all empty config.guess and config.sub in the kpcoin project
SRC=/usr/share/automake-1.18

find ~/kpcoin -name 'config.guess' -size 0 | while read f; do
    echo "Restoring: $f"
    cp "$SRC/config.guess" "$f"
    chmod +x "$f"
done

find ~/kpcoin -name 'config.sub' -size 0 | while read f; do
    echo "Restoring: $f"
    cp "$SRC/config.sub" "$f"
    chmod +x "$f"
done

echo "Done."
