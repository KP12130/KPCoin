with open('/home/kp/kpcoin/src/Makefile.am', 'r') as f:
    for i, line in enumerate(f):
        if 'bitcoind' in line and ('SOURCES' in line or 'LDADD' in line or 'bin_PROGRAMS' in line or 'kpcoind' in line.lower()):
            print(f'{i+1}: {line.strip()[:120]}')
