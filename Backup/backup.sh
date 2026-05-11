#!/bin/bash

clear

BACKUP_DIR="/root/backup"
DATE=$(date +"%Y-%m-%d")
IP=$(curl -sS --max-time 5 ipv4.icanhazip.com 2>/dev/null || curl -sS --max-time 5 ifconfig.me 2>/dev/null || echo "unknown-ip")
ZIP_FILE="/root/${IP}-${DATE}.zip"

BOT_TOKEN_FILE="/etc/Anggun/bot-token"
CHAT_ID_FILE="/etc/Anggun/chat-id"

BOT_TOKEN=$(cat "$BOT_TOKEN_FILE" 2>/dev/null)
CHAT_ID=$(cat "$CHAT_ID_FILE" 2>/dev/null)

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "             BACKUP VPS            "
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "IP VPS  : $IP"
echo "Tanggal : $DATE"
echo ""

rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

echo "[INFO] Mengumpulkan data backup..."

# === User & auth ===
cp /etc/passwd   "$BACKUP_DIR/passwd"   2>/dev/null || true
cp /etc/group    "$BACKUP_DIR/group"    2>/dev/null || true
cp /etc/shadow   "$BACKUP_DIR/shadow"   2>/dev/null || true
cp /etc/gshadow  "$BACKUP_DIR/gshadow"  2>/dev/null || true

# === Konfigurasi xray & menu ===
cp -r /etc/xray              "$BACKUP_DIR/xray"            2>/dev/null || true
cp -r /etc/Anggun            "$BACKUP_DIR/Anggun"          2>/dev/null || true
cp    /etc/kyt.txt           "$BACKUP_DIR/kyt.txt"         2>/dev/null || true
cp    /etc/issue.net         "$BACKUP_DIR/issue.net"       2>/dev/null || true

# === Service tunneling ===
cp    /etc/default/dropbear  "$BACKUP_DIR/dropbear"        2>/dev/null || true
cp    /etc/default/stunnel4  "$BACKUP_DIR/stunnel4"        2>/dev/null || true
cp -r /etc/stunnel           "$BACKUP_DIR/stunnel"         2>/dev/null || true
cp -r /etc/nginx             "$BACKUP_DIR/nginx"           2>/dev/null || true
cp -r /etc/haproxy           "$BACKUP_DIR/haproxy"         2>/dev/null || true
cp -r /etc/openvpn           "$BACKUP_DIR/openvpn"         2>/dev/null || true
cp -r /etc/wireguard         "$BACKUP_DIR/wireguard"       2>/dev/null || true
cp -r /etc/shadowsocks-libev "$BACKUP_DIR/ss-libev"        2>/dev/null || true
cp -r /etc/trojan-go         "$BACKUP_DIR/trojan-go"       2>/dev/null || true
cp -r /etc/trojan            "$BACKUP_DIR/trojan"          2>/dev/null || true
cp -r /etc/slowdns           "$BACKUP_DIR/slowdns"         2>/dev/null || true
cp -r /etc/squid             "$BACKUP_DIR/squid"           2>/dev/null || true

# === Firewall & cron ===
mkdir -p "$BACKUP_DIR"
cp /etc/iptables/rules.v4    "$BACKUP_DIR/iptables.rules"  2>/dev/null || true
cp /etc/crontab              "$BACKUP_DIR/crontab"         2>/dev/null || true
crontab -l 2>/dev/null     > "$BACKUP_DIR/cron-root"       || true

# === State & log ===
cp -r /var/lib/Anggun        "$BACKUP_DIR/var-Anggun"      2>/dev/null || true
cp -r /var/lib/kyt           "$BACKUP_DIR/var-kyt"         2>/dev/null || true
cp -r /var/lib/vnstat        "$BACKUP_DIR/var-vnstat"      2>/dev/null || true
cp    /root/log-install.txt  "$BACKUP_DIR/log-install.txt" 2>/dev/null || true
cp -r /home/vps/public_html  "$BACKUP_DIR/public_html"     2>/dev/null || true

echo "[INFO] Membuat file ZIP..."

rm -f "$ZIP_FILE"
cd /root || exit 1
zip -r "$ZIP_FILE" backup >/dev/null 2>&1

if [ ! -f "$ZIP_FILE" ]; then
    echo "[ERROR] Gagal membuat file backup."
    sleep 2
    menu-backup
    exit 1
fi

SIZE=$(du -h "$ZIP_FILE" | awk '{print $1}')

echo "[OK] Backup lokal dibuat:"
echo "$ZIP_FILE"
echo "Size: $SIZE"
echo ""

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "[WARN] Telegram belum disetting."
    echo "Silakan pilih menu 1 terlebih dahulu."
    echo ""
    read -n 1 -s -r -p "Press any key to back"
    menu-backup
    exit 0
fi

echo "[INFO] Mengupload backup ke Telegram..."

CAPTION="Backup VPS
IP: ${IP}
Tanggal: ${DATE}
Size: ${SIZE}"

RESP=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F document=@"$ZIP_FILE" \
    -F caption="$CAPTION")

if echo "$RESP" | grep -q '"ok":true'; then
    echo "[OK] Backup berhasil dikirim ke Telegram."
else
    echo "[WARN] Backup gagal dikirim ke Telegram."
    echo "File tetap tersimpan lokal:"
    echo "$ZIP_FILE"
    echo ""
    echo "Response:"
    echo "$RESP"
fi

rm -rf "$BACKUP_DIR"

echo ""
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Backup selesai."
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -n 1 -s -r -p "Press any key to back"
menu-backup
