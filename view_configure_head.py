with open('/home/kp/kpcoin/configure.ac', 'r') as f:
    lines = f.readlines()
    for i, line in enumerate(lines[10:25]):
        print(f'{i+11}: {line.strip()}')
