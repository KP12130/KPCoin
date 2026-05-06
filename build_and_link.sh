#!/bin/bash
# Full manual build script for KPCoin
set -e
cd /home/kp/kpcoin/src

SRC=/home/kp/kpcoin/src

echo "=== Building crc32c ==="
CRC_FLAGS="-I${SRC}/crc32c/include -DHAVE_BUILTIN_PREFETCH=1 -DHAVE_MM_PREFETCH=1 -DHAVE_STRONG_GETAUXVAL=1 -DCRC32C_TESTS_BUILT_WITH_GLOG=0 -DHAVE_SSE42=1 -DHAVE_ARM64_CRC32C=0 -DBYTE_ORDER_BIG_ENDIAN=0"
g++ -std=c++17 -g -O2 ${CRC_FLAGS} -c -o crc32c/src/crc32c.o crc32c/src/crc32c.cc 2>&1
g++ -std=c++17 -g -O2 ${CRC_FLAGS} -c -o crc32c/src/crc32c_portable.o crc32c/src/crc32c_portable.cc 2>&1
ar cr crc32c/libcrc32c.a crc32c/src/crc32c.o crc32c/src/crc32c_portable.o
echo "Created crc32c/libcrc32c.a"

g++ -std=c++17 -g -O2 ${CRC_FLAGS} -msse4.2 -c -o crc32c/src/crc32c_sse42.o crc32c/src/crc32c_sse42.cc 2>&1
ar cr crc32c/libcrc32c_sse42.a crc32c/src/crc32c_sse42.o
echo "Created crc32c/libcrc32c_sse42.a"

echo "=== Building leveldb ==="
LEVELDB_INCLUDES="-I${SRC}/leveldb -I${SRC}/leveldb/include -I${SRC}/crc32c/include -DLEVELDB_PLATFORM_POSIX -DLEVELDB_IS_BIG_ENDIAN=0 -DHAVE_SNAPPY=0 -DHAVE_CRC32C=1 -DHAVE_FDATASYNC=1 -DHAVE_O_CLOEXEC=1 -DFALLTHROUGH_INTENDED=[[fallthrough]] -DHAVE_FULLFSYNC=0"

LEVELDB_SRCS=(
  leveldb/db/builder.cc leveldb/db/c.cc leveldb/db/dbformat.cc
  leveldb/db/db_impl.cc leveldb/db/db_iter.cc leveldb/db/dumpfile.cc
  leveldb/db/filename.cc leveldb/db/log_reader.cc leveldb/db/log_writer.cc
  leveldb/db/memtable.cc leveldb/db/repair.cc leveldb/db/table_cache.cc
  leveldb/db/version_edit.cc leveldb/db/version_set.cc leveldb/db/write_batch.cc
  leveldb/table/block_builder.cc leveldb/table/block.cc leveldb/table/filter_block.cc
  leveldb/table/format.cc leveldb/table/iterator.cc leveldb/table/merger.cc
  leveldb/table/table_builder.cc leveldb/table/table.cc leveldb/table/two_level_iterator.cc
  leveldb/util/arena.cc leveldb/util/bloom.cc leveldb/util/cache.cc
  leveldb/util/coding.cc leveldb/util/comparator.cc leveldb/util/crc32c.cc
  leveldb/util/env.cc leveldb/util/filter_policy.cc leveldb/util/hash.cc
  leveldb/util/histogram.cc leveldb/util/logging.cc leveldb/util/options.cc
  leveldb/util/status.cc leveldb/util/env_posix.cc
)

LEVELDB_OBJS=()
for src in "${LEVELDB_SRCS[@]}"; do
  obj="${src%.cc}.o"
  echo "  CC $src"
  g++ -std=c++17 -g -O2 ${LEVELDB_INCLUDES} -c -o "$obj" "$src" 2>&1
  LEVELDB_OBJS+=("$obj")
done
ar cr leveldb/libleveldb.a "${LEVELDB_OBJS[@]}"
echo "Created leveldb/libleveldb.a"

echo "=== Building memenv ==="
g++ -std=c++17 -g -O2 ${LEVELDB_INCLUDES} -c -o leveldb/helpers/memenv/memenv.o leveldb/helpers/memenv/memenv.cc 2>&1
ar cr leveldb/libmemenv.a leveldb/helpers/memenv/memenv.o
echo "Created leveldb/libmemenv.a"

echo "=== Final link: kpcoind ==="
g++ -std=c++20 -fPIE -g -O2 \
  -I${SRC}/randomx/src \
  -Wl,-z,relro -Wl,-z,now -Wl,-z,separate-code -pie \
  -pthread \
  -o kpcoind \
  bitcoind-kpcoind.o init/bitcoind-kpcoind.o \
  -Wl,--start-group \
  libbitcoin_node.a libbitcoin_wallet.a libbitcoin_common.a libbitcoin_util.a \
  libunivalue.a libbitcoin_zmq.a libbitcoin_consensus.a \
  crypto/libbitcoin_crypto_base.a crypto/libbitcoin_crypto_sse41.a \
  crypto/libbitcoin_crypto_avx2.a crypto/libbitcoin_crypto_x86_shani.a \
  leveldb/libleveldb.a crc32c/libcrc32c.a crc32c/libcrc32c_sse42.a \
  leveldb/libmemenv.a secp256k1/.libs/libsecp256k1.a \
  ${SRC}/randomx/build/librandomx.a \
  -Wl,--end-group \
  -lminiupnpc -lnatpmp -levent_pthreads -levent -lzmq -lsqlite3 -lpthread 2>&1
echo "=== kpcoind linked ==="

echo "=== Final link: kpcoin-cli ==="
g++ -std=c++20 -fPIE -g -O2 \
  -I${SRC}/randomx/src \
  -Wl,-z,relro -Wl,-z,now -Wl,-z,separate-code -pie \
  -pthread \
  -o kpcoin-cli \
  bitcoin_cli-kpcoin-cli.o \
  -Wl,--start-group \
  libbitcoin_cli.a libunivalue.a libbitcoin_common.a libbitcoin_util.a \
  crypto/libbitcoin_crypto_base.a crypto/libbitcoin_crypto_sse41.a \
  crypto/libbitcoin_crypto_avx2.a crypto/libbitcoin_crypto_x86_shani.a \
  secp256k1/.libs/libsecp256k1.a \
  ${SRC}/randomx/build/librandomx.a \
  -Wl,--end-group \
  -levent -lpthread 2>&1
echo "=== kpcoin-cli linked ==="

echo "=== Verifying binaries ==="
ls -lah kpcoind kpcoin-cli 2>&1
file kpcoind kpcoin-cli 2>&1
./kpcoind --version 2>&1 | head -5
