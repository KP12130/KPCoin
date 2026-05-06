with open('/home/kp/kpcoin/src/Makefile.in', 'r') as f:
    for i, line in enumerate(f):
        if 'kpcoin_cli' in line or 'bitcoin_cli' in line:
            print(f'{i+1}: {line.strip()}')
