# Changelog

All notable changes vs the original `xyzstoree/gipalok` are listed here.

## v7fix-1.0 — 2026-05-21

### Added
- `lib/common.sh` — shared helpers: colors, `info/ok/warn/fail/die`, root/OS
  validation, cached IP/NIC/geo lookup, username/integer validators.
- `lib/license.sh` — real license gate against `xyzstoree/izin/main/ip`.
  - Always tries to refresh the cache on every menu render (TTL 5 min).
  - **Bug fix**: if the cache says expired/unregistered, the next call
    bypasses the TTL and re-fetches immediately. So when the admin updates
    the date in the izin repo, the VPS picks it up on the next menu render
    without any reinstall — this was the bug reported by the user.
  - Offline grace period: if the remote is unreachable but the cache was
    `active` and is < 7 days old, access stays granted.
  - Source of truth is **always** the remote repo, never the local file.
- `install/manifest.txt` + `install/install_manifest.sh` — single,
  data-driven source of truth for which scripts get installed where. Both
  `updatemenu.sh` and `force-install.sh` consume it.
- `LICENSE` (MIT), `CHANGELOG.md`, `.gitignore`, `.editorconfig`.
- `.github/workflows/ci.yml` — `shellcheck` + `python3 -m py_compile` on PR.
- New menu option: **INFO LISENSI** (was SET EXPIRED — see breaking changes).

### Changed
- All references `xyzstoree/gipalok` → `xyzstoree/v7fix` (URLs, base dir).
- Base dir `/root/gipalok` → `/root/v7fix`.
- `Menu/menu.sh`: source `lib/common.sh` + `lib/license.sh`. Expired display
  now reads from `LICENSE_EXP` (repo izin), not `/etc/Anggun/script-expired`.
  ipinfo.io, NIC and IP detection are cached so the menu renders fast.
- `updatemenu.sh` and `force-install.sh`: rewritten to consume the new
  manifest. Adding a new command now means **one line in `manifest.txt`**,
  not 80 lines of `install_file` calls.
- `tools.sh`: removed dependencies that no script uses — `php*`, `squid`,
  `nmap`, `speedtest-cli`, `libxml-parser-perl`, `libjpeg-dev`, `zlib1g-dev`,
  `python` (Python 2, EOL). Removed manual `vnstat 2.6` build from
  `humdi.net` (apt vnstat is enough for `--oneline`).
- `setup.sh`: every step is wrapped in `run_step` — failure of one step no
  longer kills the install. All output goes to `/var/log/v7fix/install.log`.
  License gate runs **before** xray/ssh setup so unregistered IPs cannot even
  install.
- `api/botvpn-api.py`:
  - Default bind `127.0.0.1` (was `0.0.0.0`). Override via
    `V7FIX_API_HOST=0.0.0.0` for advanced users running it behind nginx+TLS.
  - Token must come via header (`X-API-Key` or `Authorization: Bearer`).
    The query-string `?auth=` shortcut was removed — it leaked tokens to
    nginx/proxy access logs.
  - `createssh` now requires `POST` because it carries a password in the
    body — `405` is returned for `GET`.
  - Uses `shutil.which("xray")` instead of hardcoded `/usr/local/bin/xray`,
    so it works on systems where xray is installed via apt (`/usr/bin/xray`).
- `Menu/mbot.sh`: license check now uses `lib/license.sh` (consistent with
  the rest of the script). Previously it did its own grep-by-IP that broke
  when the network was flaky.
- `xray/cek-{ws,vless,tr}.sh`: **rewritten**. The originals parsed `###`
  and `^#& ` comment markers from `config.json` — those markers do not
  exist in the jq-based config used by this script, so listing was
  effectively broken. New versions read `clients[].email` directly via jq
  and cross-check with `xray access.log`.
- `ssh/cek.sh`, `ssh/hapus.sh`, `ssh/member.sh`, `ssh/usernew.sh`:
  removed the dead-code `curl -v google.com | grep Date` header that
  every script had — it slowed down each invocation by ~1 second and the
  resulting `$biji` variable was never used.
- `ssh/renew.sh`: validates `Days` is a positive integer (carries forward
  the fix from baseline). `egrep "^${User}:"` prevents partial-name match
  (e.g. user `john` matching `johnwick`).
- `Menu/menu.sh` opsi 10 (Install UDP): added confirmation prompt and
  return-to-menu flow. Previously the user got stuck in a shell.
- Cleaned up `running.sh` SSH-WS status reporting — was checking
  `ws-stunnel` for both NonTLS and TLS rows, showing identical status.

### Breaking changes
- `Menu/menu.sh` opsi **12** is now **INFO LISENSI** (was SET EXPIRED).
  The local file `/etc/Anggun/script-expired` is no longer consulted —
  the source of truth is the izin repo. To extend a license, the admin
  updates the date in `xyzstoree/izin/main/ip` and the VPS picks it up
  on the next menu render automatically.
- API endpoint `createssh` no longer accepts `GET`. Update bot integrations
  to use `POST` with a JSON body or form-encoded body.
- API token must now come via header. Query-string token (`?auth=...`,
  `?token=...`, `?key=...`) is rejected.

### Known limitations / future work
- The xray account metadata is still stored under `_metadata` inside
  `/etc/xray/config.json`. A future release will move it to a sidecar file
  `/etc/v7fix/users/{vmess,vless,trojan}/<user>.json`. Migration was kept
  out of this release because it would require non-trivial migration logic
  on already-running VPS deployments.
