#!/usr/bin/env python3
"""
Patch all mv .Tpo -> .Plo lines in the Makefile to first touch the .Tpo
so that libtool's -static mode doesn't break dep file tracking.
"""

path = '/home/kp/kpcoin/src/Makefile'

with open(path, 'r') as f:
    lines = f.readlines()

out = []
for line in lines:
    stripped = line.rstrip()
    # Match lines like:  $(AM_V_at)$(am__mv) something.Tpo something.Plo
    if '$(am__mv)' in stripped and '.Tpo' in stripped and '.Plo' in stripped:
        # Extract the .Tpo path
        parts = stripped.split('$(am__mv)')
        if len(parts) == 2:
            args = parts[1].strip().split()
            if len(args) >= 1:
                tpo_path = args[0]
                # Insert a touch before the mv
                indent = len(stripped) - len(stripped.lstrip('\t'))
                touch_line = '\t' * indent + f'$(AM_V_at)touch {tpo_path}\n'
                out.append(touch_line)
    out.append(line)

with open(path, 'w') as f:
    f.writelines(out)

print(f"Patched {sum(1 for l in out if '$(AM_V_at)touch' in l)} mv lines.")
