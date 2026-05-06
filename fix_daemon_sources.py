#!/usr/bin/env python3
import re

path = '/home/kp/kpcoin/src/Makefile.am'
with open(path, 'r') as f:
    content = f.read()

# Fix daemon source references
replacements = [
    ('bitcoin_daemon_sources = bitcoind.cpp', 'bitcoin_daemon_sources = kpcoind.cpp'),
    ('init/bitcoind.cpp', 'init/kpcoind.cpp'),
    ('init/bitcoin-node.cpp', 'init/kpcoin-node.cpp'),
]

for old, new in replacements:
    count = content.count(old)
    content = content.replace(old, new)
    print(f"Replaced {count}x: '{old}' -> '{new}'")

with open(path, 'w') as f:
    f.write(content)

print("Done.")
