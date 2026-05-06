import os
import subprocess

src_dir = '/home/kp/kpcoin/src'
crypto_dir = os.path.join(src_dir, 'crypto')

sources = [
    'aes.cpp', 'chacha20.cpp', 'chacha20poly1305.cpp', 'hkdf_sha256_32.cpp',
    'hmac_sha256.cpp', 'hmac_sha512.cpp', 'poly1305.cpp', 'muhash.cpp',
    'ripemd160.cpp', 'sha1.cpp', 'sha256.cpp', 'sha256_sse4.cpp',
    'sha3.cpp', 'sha512.cpp', 'siphash.cpp', 'randomx_wrapper.cpp'
]

# Note: sha256_sse41.cpp, sha256_avx2.cpp, sha256_x86_shani.cpp are separate libs

flags = [
    '-std=c++20', '-DHAVE_CONFIG_H', '-I.', '-I./config',
    '-U_FORTIFY_SOURCE', '-D_FORTIFY_SOURCE=3', '-g', '-O2',
    '-fno-extended-identifiers', '-I/home/kp/kpcoin/src/randomx/src',
    '-fpermissive'
]

def run_wsl(cmd):
    full_cmd = ['wsl', '-d', 'Ubuntu', '--', 'bash', '-c', f'cd {src_dir} && {cmd}']
    print(f"Running: {cmd}")
    return subprocess.run(full_cmd)

for s in sources:
    obj = f"crypto/{s.replace('.cpp', '.o')}"
    cmd = f"g++ {' '.join(flags)} -c -o {obj} crypto/{s}"
    run_wsl(cmd)

# Link into .a
run_wsl("ar cr crypto/libbitcoin_crypto_base.a crypto/*.o")
print("Done crypto base.")

# Specialized ones
special = [
    ('crypto/sha256_sse41.cpp', 'crypto/libbitcoin_crypto_sse41.a', '-msse4.1 -DENABLE_SSE41'),
    ('crypto/sha256_avx2.cpp', 'crypto/libbitcoin_crypto_avx2.a', '-mavx2 -DENABLE_AVX2'),
    ('crypto/sha256_x86_shani.cpp', 'crypto/libbitcoin_crypto_x86_shani.a', '-msha -msse4.2 -DENABLE_X86_SHANI'),
]

for src, lib, extra in special:
    obj = src.replace('.cpp', '.o')
    cmd = f"g++ {' '.join(flags)} {extra} -c -o {obj} {src}"
    run_wsl(cmd)
    run_wsl(f"ar cr {lib} {obj}")

print("All crypto done.")
