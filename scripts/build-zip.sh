#!/usr/bin/env bash
# Dev sideload build: bundle the frontend and zip the plugin for Decky's
# "install from zip". The Decky store does NOT use this — its CI builds the
# frontend with pnpm and libsodium via backend/ (output lands in bin/).
#
# For a local zip, py_modules/libsodium.so is bundled so the plugin works
# without the store's bin/ output. Build one with backend/entrypoint.sh in
# Docker, or copy a system libsodium built against glibc <= 2.33.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f py_modules/libsodium.so ]; then
  for so in /lib/x86_64-linux-gnu/libsodium.so.23 /usr/lib/libsodium.so; do
    [ -f "$so" ] && cp "$so" py_modules/libsodium.so && break
  done
fi
[ -f py_modules/libsodium.so ] || echo "warn: no libsodium.so bundled — device will rely on system copy"

pnpm run build

mkdir -p out
rm -f out/findmydeck-plugin.zip
zip -qr out/findmydeck-plugin.zip plugin.json main.py py_modules dist package.json LICENSE
echo "wrote out/findmydeck-plugin.zip"
