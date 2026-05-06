with open('/home/kp/kpcoin/src/Makefile.in', 'r') as f:
    for i, line in enumerate(f):
        if 'libbitcoin_wallet' in line or 'libkpcoin_wallet' in line:
            print(f'{i+1}: {line.strip()[:100]}')
