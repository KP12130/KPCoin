#!/usr/bin/env python3
path = '/home/kp/kpcoin/src/Makefile.am'
with open(path, 'r') as f:
    content = f.read()

replacements = [
    ('bitcoin-cli.cpp', 'kpcoin-cli.cpp'),
    ('bitcoin-tx.cpp', 'kpcoin-tx.cpp'),
    ('bitcoin-wallet.cpp', 'kpcoin-wallet.cpp'),
    ('init/bitcoin-wallet.cpp', 'init/kpcoin-wallet.cpp'),
    ('bitcoin-util.cpp', 'kpcoin-util.cpp'),
    ('bitcoin-chainstate.cpp', 'kpcoin-chainstate.cpp'),
]

for old, new in replacements:
    count = content.count(old)
    content = content.replace(old, new)
    print(f"Replaced {count}x: '{old}' -> '{new}'")

with open(path, 'w') as f:
    f.write(content)

print("Done.")
