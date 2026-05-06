import re

path = '/home/kp/kpcoin/src/kernel/chainparams.cpp'
with open(path) as f:
    c = f.read()

# Replace entire checkpointData = { ... }; blocks with empty version
fixed = re.sub(
    r'checkpointData\s*=\s*\{.*?\}\s*;',
    'checkpointData = {\n            {}\n        };',
    c,
    flags=re.DOTALL
)

with open(path, 'w') as f:
    f.write(fixed)

print('Fixed checkpointData blocks.')

# Verify
matches = re.findall(r'checkpointData\s*=\s*\{[^}]*\}[^;]*;', fixed)
for m in matches:
    print(repr(m[:100]))
