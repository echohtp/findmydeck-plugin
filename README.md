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
- Commands (mode changes and ring) are Ed25519-detached-signed by the owner
  with a strictly monotonic counter; the device verifies the exact received
  payload bytes before parsing. The server cannot forge or replay commands,
  and cannot make the Deck ring on its own.
- Unenrolling from the QAM requires the recovery password: the frontend
  re-derives the keys and signs an unenroll payload the backend verifies, so
  whoever merely holds the Deck cannot switch tracking off from the menus.
- The plugin refuses plain-`http` server URLs (loopback excepted for
  development).

Known limitations, on purpose and worth knowing:

- The server stores the KDF salt and public keys, so a malicious server
  operator can mount an **offline password-guessing attack**. Argon2id at
  256 MiB makes each guess expensive; the UI enforces a 10+ character
  password, and a genuinely strong passphrase is your real defense.
- The lost-mode **finder↔owner chat is plaintext to the server** (the finder
  has no key material). Location reports stay sealed; chat is a relay
  feature, not a zero-knowledge one.
- Lost mode is a loud banner, not a lock. A wipe/reinstall removes the
  plugin; this is recovery tooling, not theft prevention hardware.

## Why the `_root` flag

Network scanning (`py_modules/fmsd_scan.py`) reads Wi-Fi/BSSID environment
data used to locate the device; this requires root on SteamOS.

## Layout

- `main.py` — Decky backend: heartbeat loop, command poll, report upload,
  disk retry queue. Wake-from-suspend (detected via CLOCK_BOOTTIME vs
  CLOCK_MONOTONIC divergence, plus a frontend resume hook) is treated as a
  network-connect event and reports immediately.
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
