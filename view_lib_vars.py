with open('/home/kp/kpcoin/src/Makefile.am', 'r') as f:
    lines = f.readlines()
    for i, line in enumerate(lines[0:100]):
        if 'LIBBITCOIN_' in line:
            print(f'{i+1}: {line.strip()}')
