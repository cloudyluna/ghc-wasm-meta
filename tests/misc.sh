#!/usr/bin/env bash

set -euo pipefail

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/haskell/time/archive/refs/heads/master.tar.gz | tar xz --strip-components=1
autoreconf -i
wasm32-wasi-cabal build test:ShowDefaultTZAbbreviations
$CROSS_EMULATOR $(wasm32-wasi-cabal list-bin test:ShowDefaultTZAbbreviations)
wasm32-wasi-cabal build test:ShowTime
$CROSS_EMULATOR $(wasm32-wasi-cabal list-bin test:ShowTime)
popd

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/haskell/unix/archive/refs/heads/master.tar.gz | tar xz --strip-components=1
cp /tmp/.ghc-wasm/wasi-sdk/share/misc/config.* .
autoreconf -i
wasm32-wasi-cabal --project-file=cabal.project.wasm32-wasi build
./test-wasm32-wasi.mjs
popd

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/corsis/clock/archive/refs/heads/master.tar.gz | tar xz --strip-components=1
wasm32-wasi-cabal build
popd

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/haskell/zlib/archive/refs/heads/master.tar.gz | tar xz --strip-components=1
mv cabal.project.wasi cabal.project
cp $CI_PROJECT_DIR/cabal.project.local .
wasm32-wasi-cabal build --enable-tests all
cd zlib
$CROSS_EMULATOR $(find .. -type f -name tests.wasm)
popd

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/Bodigrim/bitvec/archive/refs/heads/master.tar.gz | tar xz --strip-components=1
mv cabal.project.wasi cabal.project.local
wasm32-wasi-cabal build --enable-tests
$CROSS_EMULATOR $(find . -type f -name bitvec-tests.wasm)
popd

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/UnkindPartition/tasty/archive/refs/heads/master.tar.gz | tar xz --strip-components=1
cp $CI_PROJECT_DIR/cabal.project.local .
wasm32-wasi-cabal build all

readonly TEST_WRAPPERS="$(mktemp -d -p /tmp)"
export PATH=$TEST_WRAPPERS:$PATH
for test in tasty-core-tests exit-status-test resource-release-test failing-pattern-test; do
  echo '#!/bin/sh' > "$TEST_WRAPPERS/$test"
  echo "exec $CROSS_EMULATOR $(find $PWD -type f -name $test.wasm) \"\$@\"" \
    >> "$TEST_WRAPPERS/$test"
  chmod +x "$TEST_WRAPPERS/$test"
done

(cd core-tests && tasty-core-tests)
core-tests/exit-status-tests.sh
core-tests/failing-pattern-test.sh

popd

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/Bodigrim/tasty-bench/archive/refs/heads/master.tar.gz | tar xz --strip-components=1
wasm32-wasi-cabal build --enable-benchmarks
$CROSS_EMULATOR $(find . -type f -name bench-fibo.wasm)
popd

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/extism/haskell-pdk/archive/refs/heads/main.tar.gz | tar xz --strip-components=1
wasm32-wasi-cabal build all
popd

pushd "$(mktemp -d)"
curl -f -L --retry 5 https://github.com/AntanasKal/SpaceInvaders/archive/refs/heads/develop.tar.gz | tar xz --strip-components=1
cp $CI_PROJECT_DIR/cabal.project.local .
wasm32-wasi-cabal build wasmBuild
popd
