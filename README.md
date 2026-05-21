# v7fix

VPS tunneling autoscript for Ubuntu/Debian — SSH, Dropbear, Stunnel, SSH
WebSocket, Xray (VMess / VLess / Trojan), Trojan-Go, OpenVPN, plus a Telegram
bot, REST API, traffic accounting, and per-user IP/quota limits.

This repo is a hardened, bug-fixed rebuild of [`xyzstoree/gipalok`](https://github.com/xyzstoree/gipalok).
See [`CHANGELOG.md`](CHANGELOG.md) for the full diff.

> **Tested on**: Ubuntu 20.04, 22.04, 24.04 — Debian 10, 11, 12.

## Install

Fresh VPS, as `root`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/xyzstoree/v7fix/main/setup.sh)
```

Or, if you only want to refresh the command files (no apt, no xray reinstall):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/xyzstoree/v7fix/main/force-install.sh)
```

After install, log out and log back in — the menu opens automatically.

## License gate

Access is gated by your VPS public IP being registered at
[`xyzstoree/izin`](https://github.com/xyzstoree/izin). Format per line:

```
### USERNAME YYYY-MM-DD IP
```

The check runs on every menu render. **You do not need to reinstall** the
script when the admin extends the date in the izin repo — your VPS will
detect the change automatically on the next menu render. This was a bug in
the previous codebase and is fixed in v7fix.

If you ever lose internet on the VPS, a 7-day offline grace period applies
as long as the last successful check was `active`.

## Commands

After install you have these commands in `PATH` (`/usr/local/bin/`):

| Group | Commands |
|---|---|
| Main | `menu`, `menu-ssh`, `menu-vmess`, `menu-vless`, `menu-trojan`, `menu-set`, `menu-bot`, `menu-backup`, `menu-trial`, `running` |
| SSH user mgmt | `usernew`, `trial`, `renew`, `delete`, `hapus`, `cek`, `member`, `user-lock`, `user-unlock`, `autokill`, `ceklim`, `tendang` |
| Xray VMess | `add-ws`, `trial-ws`, `renew-ws`, `del-ws`, `cek-ws` |
| Xray VLess | `add-vless`, `trial-vless`, `renew-vless`, `del-vless`, `cek-vless` |
| Xray Trojan | `add-tr`, `trial-tr`, `renew-tr`, `del-tr`, `cek-tr` |
| Trojan-Go | `addtrgo`, `trialtrojango`, `renewtrgo`, `deltrgo`, `cektrgo` |
| Backup | `backup`, `restore`, `autobackup`, `set-telegram`, `set-br` |
| Maintenance | `updatemenu`, `force-install`, `clearcache`, `clearlog`, `restart` |

## REST API

The bot API exposes account-create endpoints. By default it listens on
`127.0.0.1:5889` — put it behind nginx + TLS for remote access. Override
the bind with `V7FIX_API_HOST=0.0.0.0` if you understand the risk.

```bash
# Generate / read token
cat /etc/Anggun/api-token

# Token MUST be sent via header (the old ?auth=... is rejected for security)
TOKEN=$(cat /etc/Anggun/api-token)

# Create SSH (POST only — body carries password)
curl -X POST http://127.0.0.1:5889/createssh \
  -H "X-API-Key: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user":"alice","password":"secret","exp":30,"iplimit":2}'

# Create Vmess
curl -X POST http://127.0.0.1:5889/createvmess \
  -H "X-API-Key: $TOKEN" \
  -d '{"user":"alice","exp":30,"iplimit":2,"quota":50}'
```

Endpoints: `/health`, `/status`, `/createssh`, `/createvmess`,
`/createvless`, `/createtrojan`.

## Repo layout

```
v7fix/
├── lib/                      # Shared helpers (sourced by other scripts)
│   ├── common.sh
│   └── license.sh
├── install/                  # Install manifest + helper
│   ├── manifest.txt
│   └── install_manifest.sh
├── Menu/                     # TUI screens (menu, menu-ssh, ...)
├── ssh/                      # SSH/OpenVPN account management
├── sshws/                    # SSH-over-WebSocket
├── xray/                     # VMess / VLess / Trojan account management
├── Port/                     # Port change scripts
├── Queue/                    # Per-user IP & quota limits
├── Backup/                   # Backup/restore + Telegram delivery
├── api/                      # botvpn-api.py + installer
├── setup.sh                  # First-run installer
├── tools.sh                  # apt deps
├── updatemenu.sh             # Refresh from /root/v7fix (git pull + manifest)
├── force-install.sh          # Refresh from raw GitHub (no git, no /root/v7fix)
└── ...
```

## Troubleshooting

**Menu shows `AKSES SCRIPT DITOLAK`**
Your VPS public IP is not in `xyzstoree/izin/main/ip`, or the date there
has passed. Ask the admin to register/extend.

**API requests get `401 Unauthorized`**
The token must be sent in the `X-API-Key` or `Authorization: Bearer`
header. Query-string tokens are no longer accepted.

**`createssh` returns `405`**
Use `POST`. `GET` is rejected because passwords would otherwise leak into
proxy access logs.

**`xray test` fails after add/del/renew**
Each script writes a `.tmp` next to `config.json` and verifies it with
`xray test` before swapping. If the test fails the original config is
preserved. Backup files `config.json.bak.<epoch>` are kept after every
mutation; `ls -t /etc/xray/config.json.bak.* | head -3` and `cp` the most
recent one back if needed.

**Menu is slow on every render**
The first render fetches IP, ISP, city, license, vnstat. Subsequent renders
within 5 minutes use the cache. If it stays slow, check
`curl -m 3 https://ipinfo.io/ip` from the VPS — most likely your VPS has
spotty outbound connectivity to ipinfo.

## Security notes

- The bot API binds `127.0.0.1` by default. Front it with nginx + Let's
  Encrypt if you need remote access.
- The API token lives at `/etc/Anggun/api-token` (mode 600, owned by root).
  Rotate by deleting the file — the API will regenerate one on next start.
- `setup.sh` opens TCP ports 22, 80, 443, 109, 110, 143, 447, 500, 777,
  8080, 8880, 2082, 2083, 2086, 8443, 5889 in iptables. Audit before
  running on a production network.

## License

[MIT](LICENSE) — see also `CHANGELOG.md` for what was fixed vs the upstream
[`xyzstoree/gipalok`](https://github.com/xyzstoree/gipalok).
