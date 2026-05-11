#!/bin/bash
# ============================================================================
# INSTALL BOTVPN API TYPE 2
# Port: 5889
# ============================================================================

set -e

REPO_DIR="/root/gipalok"
API_SRC="$REPO_DIR/api/botvpn-api.py"
API_DEST="/usr/local/bin/botvpn-api.py"
SERVICE="/etc/systemd/system/botvpn-api.service"
TOKEN_FILE="/etc/Anggun/api-token"

green='\033[0;32m'
red='\033[1;31m'
NC='\033[0m'

info() {
    echo -e "[ ${green}INFO${NC} ] $1"
}

err() {
    echo -e "[ ${red}ERROR${NC} ] $1"
}

if [[ $EUID -ne 0 ]]; then
    err "Script harus dijalankan sebagai root!"
    exit 1
fi

clear
info "Installing BotVPN API Type 2..."

apt update -y >/dev/null 2>&1 || true
apt install -y python3 curl jq iptables netfilter-persistent uuid-runtime >/dev/null 2>&1 || true

mkdir -p /etc/Anggun
mkdir -p /usr/local/bin

if [ ! -f "$API_SRC" ]; then
    err "File tidak ditemukan: $API_SRC"
    exit 1
fi

cp "$API_SRC" "$API_DEST"
chmod +x "$API_DEST"

if [ ! -s "$TOKEN_FILE" ]; then
    uuidgen > "$TOKEN_FILE" 2>/dev/null || cat /proc/sys/kernel/random/uuid > "$TOKEN_FILE"
fi

chmod 600 "$TOKEN_FILE"

cat > "$SERVICE" <<EOF
[Unit]
Description=BotVPN API Type 2
After=network.target xray.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 $API_DEST
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

iptables -C INPUT -p tcp --dport 5889 -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport 5889 -j ACCEPT
netfilter-persistent save >/dev/null 2>&1 || iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

systemctl daemon-reload
systemctl enable --now botvpn-api
systemctl restart botvpn-api

sleep 1

clear
info "BotVPN API installed."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " API URL   : http://DOMAIN:5889"
echo " API Token : $(cat "$TOKEN_FILE")"
echo " API Type  : 2"
echo " Service   : botvpn-api"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Test:"
echo "curl \"http://127.0.0.1:5889/health\""
echo "curl \"http://127.0.0.1:5889/createssh?user=testapi&password=123&exp=1&iplimit=2&auth=$(cat "$TOKEN_FILE")\""
echo ""
