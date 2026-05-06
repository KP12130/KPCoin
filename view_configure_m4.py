with open('/home/kp/kpcoin/configure.ac', 'r') as f:
    for i, line in enumerate(f):
        if 'm4_include' in line:
            print(f'{i+1}: {line.strip()}')
