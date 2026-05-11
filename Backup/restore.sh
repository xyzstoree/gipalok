#!/bin/bash

clear

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "              RESTORE VPS          "
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Masukkan link file backup ZIP."
echo "Bisa link Telegram direct/file lokal juga."
echo ""
echo "Contoh lokal:"
echo "/root/147.139.200.112-2026-05-08.zip"
echo ""
read -rp "File/URL Backup: " backup_input

if [ -z "$backup_input" ]; then
    echo "Input kosong."
    sleep 2
    menu-backup
    exit 1
fi

cd /root || exit 1
rm -rf /root/backup /root/restore.zip

if [ -f "$backup_input" ]; then
    cp "$backup_input" /root/restore.zip
else
    wget -O /root/restore.zip "$backup_input"
fi

if [ ! -f /root/restore.zip ]; then
    echo "File restore tidak ditemukan."
    sleep 2
    menu-backup
    exit 1
fi

echo "[INFO] Extract backup..."
unzip -o /root/restore.zip >/dev/null 2>&1

if [ ! -d /root/backup ]; then
    echo "Folder backup tidak ditemukan. File ZIP tidak valid."
    rm -f /root/restore.zip
    sleep 2
    menu-backup
    exit 1
fi

echo "[INFO] Restore data..."

cd /root/backup || exit 1

# === User & auth ===
cp passwd  /etc/passwd  2>/dev/null || true
cp group   /etc/group   2>/dev/null || true
cp shadow  /etc/shadow  2>/dev/null || true
cp gshadow /etc/gshadow 2>/dev/null || true

# === Konfigurasi xray & menu (pakai -rT supaya menimpa, bukan nested) ===
[ -d xray ]     && mkdir -p /etc/xray     && cp -rT xray     /etc/xray     2>/dev/null || true
[ -d Anggun ]   && mkdir -p /etc/Anggun   && cp -rT Anggun   /etc/Anggun   2>/dev/null || true
cp kyt.txt     /etc/kyt.txt   2>/dev/null || true
cp issue.net   /etc/issue.net 2>/dev/null || true

# === Service tunneling ===
cp dropbear  /etc/default/dropbear  2>/dev/null || true
cp stunnel4  /etc/default/stunnel4  2>/dev/null || true
[ -d stunnel ]     && mkdir -p /etc/stunnel           && cp -rT stunnel     /etc/stunnel           2>/dev/null || true
[ -d nginx ]       && mkdir -p /etc/nginx             && cp -rT nginx       /etc/nginx             2>/dev/null || true
[ -d haproxy ]     && mkdir -p /etc/haproxy           && cp -rT haproxy     /etc/haproxy           2>/dev/null || true
[ -d openvpn ]     && mkdir -p /etc/openvpn           && cp -rT openvpn     /etc/openvpn           2>/dev/null || true
[ -d wireguard ]   && mkdir -p /etc/wireguard         && cp -rT wireguard   /etc/wireguard         2>/dev/null || true
[ -d ss-libev ]    && mkdir -p /etc/shadowsocks-libev && cp -rT ss-libev    /etc/shadowsocks-libev 2>/dev/null || true
[ -d trojan-go ]   && mkdir -p /etc/trojan-go         && cp -rT trojan-go   /etc/trojan-go         2>/dev/null || true
[ -d trojan ]      && mkdir -p /etc/trojan            && cp -rT trojan      /etc/trojan            2>/dev/null || true
[ -d slowdns ]     && mkdir -p /etc/slowdns           && cp -rT slowdns     /etc/slowdns           2>/dev/null || true
[ -d squid ]       && mkdir -p /etc/squid             && cp -rT squid       /etc/squid             2>/dev/null || true

# === Firewall & cron ===
if [ -f iptables.rules ]; then
    mkdir -p /etc/iptables
    cp iptables.rules /etc/iptables/rules.v4 2>/dev/null || true
    iptables-restore < /etc/iptables/rules.v4 2>/dev/null || true
fi
cp crontab /etc/crontab 2>/dev/null || true
[ -f cron-root ] && crontab cron-root 2>/dev/null || true

# === State & log ===
[ -d var-Anggun ] && mkdir -p /var/lib/Anggun && cp -rT var-Anggun /var/lib/Anggun 2>/dev/null || true
[ -d var-kyt ]    && mkdir -p /var/lib/kyt    && cp -rT var-kyt    /var/lib/kyt    2>/dev/null || true
[ -d var-vnstat ] && mkdir -p /var/lib/vnstat && cp -rT var-vnstat /var/lib/vnstat 2>/dev/null || true
cp log-install.txt /root/log-install.txt 2>/dev/null || true
[ -d public_html ] && mkdir -p /home/vps/public_html && cp -rT public_html /home/vps/public_html 2>/dev/null || true

echo "[INFO] Restart service..."

systemctl daemon-reload                  2>/dev/null || true
systemctl restart xray                   2>/dev/null || true
systemctl restart nginx                  2>/dev/null || true
systemctl restart dropbear               2>/dev/null || true
systemctl restart ssh                    2>/dev/null || true
systemctl restart stunnel4               2>/dev/null || true
systemctl restart ws                     2>/dev/null || true
systemctl restart haproxy                2>/dev/null || true
systemctl restart openvpn@server-tcp     2>/dev/null || true
systemctl restart openvpn@server-udp     2>/dev/null || true
systemctl restart wg-quick@wg0           2>/dev/null || true
systemctl restart shadowsocks-libev      2>/dev/null || true
systemctl restart trojan-go              2>/dev/null || true
systemctl restart vnstat                 2>/dev/null || true
systemctl restart cron                   2>/dev/null || true

rm -rf /root/backup /root/restore.zip

echo ""
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Restore selesai."
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -n 1 -s -r -p "Press any key to back"
menu-backup
