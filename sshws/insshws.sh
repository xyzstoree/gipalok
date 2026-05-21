#!/bin/bash
set -e

REPO=${REPO:-https://raw.githubusercontent.com/xyzstoree/v7fix/main/}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

install_file() {
  local src="$1"
  local dest="$2"

  if [ -f "$ROOT_DIR/$src" ]; then
    cp "$ROOT_DIR/$src" "$dest"
  else
    wget -q -O "$dest" "${REPO}${src}"
  fi
}

echo "[INFO] Installing SSH WebSocket service"

apt update
apt install -y python2 || apt install -y python-is-python2 || true

install_file ssh/ws-dropbear /usr/bin/ws
install_file sshws/ws-stunnel.service /etc/systemd/system/ws.service

[ -s /usr/bin/ws ] || { echo "[ERROR] /usr/bin/ws gagal install"; exit 1; }
[ -s /etc/systemd/system/ws.service ] || { echo "[ERROR] ws.service gagal install"; exit 1; }

chmod +x /usr/bin/ws
chmod 644 /etc/systemd/system/ws.service

systemctl disable --now sshws ws-dropbear ws-stunnel 2>/dev/null || true

systemctl daemon-reload
systemctl enable --now ws
systemctl restart ws

echo "[OK] ws.service installed"
systemctl status ws --no-pager -l || true
