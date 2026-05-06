with open('/home/kp/kpcoin/src/Makefile.am', 'r') as f:
    lines = f.readlines()
    for i, line in enumerate(lines[760:790]):
        print(f'{761+i}: {line.strip()}')
