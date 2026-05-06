with open('/home/kp/kpcoin/src/Makefile.am', 'r') as f:
    for i, line in enumerate(f):
        if 'PROGRAMS' in line:
            print(f'{i+1}: {line.strip()}')
