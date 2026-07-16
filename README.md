# Find My Steam Deck (Decky plugin)

Zero-knowledge anti-theft & recovery for the Steam Deck. The device sends
sealed location reports only the owner can decrypt, and accepts only
commands the owner has signed. The server is untrusted storage + relay.

This repo is the Decky plugin only. The server, owner dashboard, and shared
crypto test suite live in the [findmydeck](https://github.com/echohtp/findmydeck)
monorepo; `src/lib/crypto.mjs` and `py_modules/fmsd_crypto.py` are the
vendored device-side halves of that crypto core (wire-compatibility is
proven by the monorepo's interop tests).

## Security model (short version)

- Enrollment happens in the frontend: password → Argon2id → X25519 + Ed25519
  keypairs. Only the **public** keys reach the Python backend and the server;
  password and secret keys are wiped from memory before the call returns.
- Reports are `crypto_box_seal`ed to the owner's X25519 public key with an
  ephemeral sender key — the device cannot decrypt its own past reports.
- Commands (lost/stolen/normal, ring, messages) are Ed25519-detached-signed
  by the owner; the device verifies the exact received payload bytes before
  parsing. The server cannot forge commands.
- In `stolen` mode the QAM panel renders exactly as in `normal` mode; only
  `lost` mode is visible on-device.

## Why the `_root` flag

Network scanning (`py_modules/fmsd_scan.py`) reads Wi-Fi/BSSID environment
data used to locate the device; this requires root on SteamOS.

## Layout

- `main.py` — Decky backend: heartbeat loop, command poll, report upload,
  disk retry queue. Wake-from-suspend is treated as a connect event.
- `py_modules/` — pure-stdlib Python: crypto (ctypes → libsodium), HTTP
  client, state machine, scanner, retry queue.
- `src/` — React QAM frontend (`@decky/ui`), enrollment + lost/ring screens.
- `backend/` — Decky CI Docker step: builds libsodium from a pinned,
  checksum-verified source release into `backend/out/`, which the store
  packaging places in the plugin's `bin/`.

## Build

Store CI: `pnpm i && pnpm run build` for the frontend, `backend/` for
libsodium — nothing prebuilt is committed.

Local dev sideload zip:

```bash
pnpm i
./scripts/build-zip.sh   # writes out/findmydeck-plugin.zip
```

## License

ISC — see [LICENSE](LICENSE).
