#!/bin/bash
# Build libsodium from source (pinned release + checksum) for the plugin's
# ctypes crypto (py_modules/fmsd_crypto.py). Decky's CI copies /backend/out
# into the packaged plugin's bin/ directory.
set -euo pipefail

VERSION=1.0.20
SHA256=ebb65ef6ca439333c2bb41a0c1990587288da07f6c7fd07cb3a18cc18d30ce19
TARBALL="libsodium-${VERSION}.tar.gz"

cd /tmp
curl -fsSLO "https://github.com/jedisct1/libsodium/releases/download/${VERSION}-RELEASE/${TARBALL}"
echo "${SHA256}  ${TARBALL}" | sha256sum -c -
tar xzf "${TARBALL}"
cd "libsodium-${VERSION}"

./configure --disable-dependency-tracking
make -j"$(nproc)"

mkdir -p /backend/out
cp -L src/libsodium/.libs/libsodium.so /backend/out/libsodium.so
echo "built $(sha256sum /backend/out/libsodium.so)"
