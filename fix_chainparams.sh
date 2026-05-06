#!/bin/bash
# Fix the broken chainparams.cpp checkpoint sections
# The regex left broken C++ struct syntax - we need to properly empty all checkpoints

CHAINPARAMS=~/kpcoin/src/kernel/chainparams.cpp

# Use Python to properly fix all checkpoint blocks
python3 << 'PYEOF'
import re

filepath = '/root/kpcoin/src/kernel/chainparams.cpp' if __import__('os').path.exists('/root/kpcoin') else '/home/kp/kpcoin/src/kernel/chainparams.cpp'

with open(filepath, 'r') as f:
    content = f.read()

# Fix the broken checkpoint pattern:
# The regex produced: checkpointData = { { } }, <old data> } };
# We need to replace the entire checkpointData block with empty one

# Pattern: matches checkpointData = { ... }; including the broken parts
# More specifically, we need to find the whole block and replace it
def fix_checkpoint_block(text):
    """Replace all checkpointData blocks with empty ones."""
    # Find each checkpointData assignment and replace with empty
    result = []
    i = 0
    while i < len(text):
        # Look for checkpointData = {
        idx = text.find('checkpointData = {', i)
        if idx == -1:
            result.append(text[i:])
            break
        
        result.append(text[i:idx])
        result.append('checkpointData = {\n            {}\n        }')
        
        # Find the matching closing }; for the checkpointData block
        brace_count = 0
        j = idx + len('checkpointData = {')
        while j < len(text):
            if text[j] == '{':
                brace_count += 1
            elif text[j] == '}':
                if brace_count == 0:
                    # This closes the checkpointData = {
                    # Skip the closing }; or },
                    j += 1
                    while j < len(text) and text[j] in ' \t;,\n':
                        if text[j] == ';':
                            j += 1
                            break
                        j += 1
                    break
                brace_count -= 1
            j += 1
        i = j
    
    return ''.join(result)

fixed = fix_checkpoint_block(content)

with open(filepath, 'w') as f:
    f.write(fixed)

print(f"Fixed checkpointData blocks in {filepath}")
PYEOF

echo "Done fixing chainparams.cpp"
echo "Verifying the fix..."
grep -A 3 "checkpointData" ~/kpcoin/src/kernel/chainparams.cpp | head -20
