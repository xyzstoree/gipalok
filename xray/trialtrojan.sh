#!/bin/bash
set -e

clear

CONFIG="/etc/xray/config.json"
XRAY_BIN="$(command -v xray || echo /usr/local/bin/xray)"
QUEUE_DIR="/etc/Anggun/Queue/trojan"
LOG_FILE="/etc/log-create-user.log"

mkdir -p "$QUEUE_DIR/ip" "$QUEUE_DIR/quota" /etc/Anggun
touch "$LOG_FILE"

source /var/lib/Anggun/ipvps.conf 2>/dev/null || true

domain=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || echo "-")
bug="${IP:-$domain}"

tls="$(grep -w "Trojan TLS" ~/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"
none="$(grep -w "Trojan None TLS" ~/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"

[ -z "$tls" ] && tls="443"
[ -z "$none" ] && none="80"

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m        Trial Trojan Account        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
echo "Format durasi:"
echo "  5m = 5 menit"
echo "  3h = 3 jam"
echo "  3d = 3 hari"
echo ""
read -rp "Durasi Trial : " duration
read -rp "Limit IP     : " iplimit
read -rp "Quota GB     : " quota

[ -z "$duration" ] && duration="1d"
[ -z "$iplimit" ] && iplimit="2"
[ -z "$quota" ] && quota="0"

if ! echo "$duration" | grep -Eq '^[0-9]+[mMhHdD]$'; then
    echo "Format durasi salah. Contoh: 5m, 3h atau 3d"
    sleep 2
    menu-trojan 2>/dev/null || menu
    exit 1
fi

[[ "$iplimit" =~ ^[0-9]+$ ]] || iplimit="2"
[[ "$quota" =~ ^[0-9]+$ ]] || quota="0"

num=$(echo "$duration" | sed 's/[^0-9]//g')
unit=$(echo "$duration" | sed 's/[0-9]//g' | tr 'A-Z' 'a-z')

if [ "$unit" = "m" ]; then
    exp_display=$(date -d "+$num minutes" +"%Y-%m-%d %H:%M:%S")
    delete_time=$(date -d "+$num minutes" +"%H:%M %Y-%m-%d")
    duration_text="$num Menit"
elif [ "$unit" = "h" ]; then
    exp_display=$(date -d "+$num hours" +"%Y-%m-%d %H:%M:%S")
    delete_time=$(date -d "+$num hours" +"%H:%M %Y-%m-%d")
    duration_text="$num Jam"
elif [ "$unit" = "d" ]; then
    exp_display=$(date -d "+$num days" +"%Y-%m-%d %H:%M:%S")
    delete_time=$(date -d "+$num days" +"%H:%M %Y-%m-%d")
    duration_text="$num Hari"
else
    echo "Format durasi salah. Contoh: 5m, 3h atau 3d"
    sleep 2
    menu-trojan 2>/dev/null || menu
    exit 1
fi

user="Trial-$(tr -dc 'A-Z0-9' </dev/urandom | head -c 4)"
uuid=$(cat /proc/sys/kernel/random/uuid)
quota_bytes=$((quota * 1024 * 1024 * 1024))

if jq --arg user "$user" '[.inbounds[]?.settings.clients[]? | select(.email==$user)] | length' "$CONFIG" | grep -qv '^0$'; then
    echo "User sudah ada, coba ulang."
    sleep 2
    menu-trojan 2>/dev/null || menu
    exit 1
fi

backup="${CONFIG}.bak.$(date +%s)"
cp "$CONFIG" "$backup"

tmp=$(mktemp --suffix=.json)

jq --arg user "$user" --arg uuid "$uuid" '
  .inbounds |= map(
    if (.tag == "trojan-ws" or .tag == "trojan-grpc") then
      .settings.clients = ((.settings.clients // []) + [{"password": $uuid, "email": $user}])
    else
      .
    end
  )
' "$CONFIG" > "$tmp"

if ! "$XRAY_BIN" run -test -config "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    echo "Config Xray tidak valid. Batal."
    sleep 2
    menu-trojan 2>/dev/null || menu
    exit 1
fi

mv "$tmp" "$CONFIG"

if systemctl restart xray >/dev/null 2>&1; then
    api_status="Created, Xray restarted"
else
    cp "$backup" "$CONFIG"
    systemctl restart xray >/dev/null 2>&1 || true
    echo "[ERROR] Gagal restart Xray. Akun trial dibatalkan."
    sleep 3
    menu-trojan 2>/dev/null || menu
    exit 1
fi

[ "$iplimit" -gt 0 ] && echo "$iplimit" > "$QUEUE_DIR/ip/$user"
[ "$quota" -gt 0 ] && echo "$quota_bytes" > "$QUEUE_DIR/quota/$user"

cleaner="/usr/local/bin/clean-trojan-${user}.sh"

cat > "$cleaner" <<EOF
#!/bin/bash
CONFIG="/etc/xray/config.json"
XRAY_BIN="\$(command -v xray || echo /usr/local/bin/xray)"
USER="$user"
LOG="/var/log/trial-cleaner.log"

echo "\$(date) Cleaning Trojan \$USER" >> "\$LOG"

tmp=\$(mktemp --suffix=.json)

jq --arg user "\$USER" '
  .inbounds |= map(
    if (.tag == "trojan-ws" or .tag == "trojan-grpc") then
      .settings.clients = [ .settings.clients[]? | select(.email != \$user) ]
    else
      .
    end
  )
' "\$CONFIG" > "\$tmp"

if "\$XRAY_BIN" run -test -config "\$tmp" >/dev/null 2>&1; then
    mv "\$tmp" "\$CONFIG"
    systemctl restart xray >/dev/null 2>&1 || true
    echo "\$(date) Cleaned Trojan \$USER OK" >> "\$LOG"
else
    rm -f "\$tmp"
    echo "\$(date) Cleaned Trojan \$USER FAILED config invalid" >> "\$LOG"
fi

rm -f /etc/Anggun/Queue/trojan/ip/\$USER /etc/Anggun/Queue/trojan/quota/\$USER
rm -f "$cleaner"
EOF

chmod +x "$cleaner"

if ! command -v at >/dev/null 2>&1; then
    apt install -y at >/dev/null 2>&1 || true
    systemctl enable --now atd >/dev/null 2>&1 || true
fi

echo "$cleaner" | at "$delete_time" >/dev/null 2>&1 || true

trojanlink1="trojan://${uuid}@${bug}:${tls}?path=%2Ftrojan-ws&security=tls&host=${domain}&type=ws&sni=${domain}#${user}"
trojanlink2="trojan://${uuid}@${bug}:${none}?path=%2Ftrojan-ws&security=none&host=${domain}&type=ws#${user}"
trojanlink3="trojan://${uuid}@${bug}:${tls}?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${domain}#${user}"

clear
{
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "\E[0;41;36m           Trial Trojan             \E[0m"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Remarks      : $user"
echo -e "Address/Bug  : $bug"
echo -e "Host/SNI     : $domain"
echo -e "Port TLS     : $tls"
echo -e "Port NTLS    : $none"
echo -e "Password     : $uuid"
echo -e "Durasi       : $duration_text"
echo -e "Expired      : $exp_display"
echo -e "Limit IP     : $iplimit"
echo -e "Quota        : $quota GB"
echo -e "Network      : ws/grpc"
echo -e "Path         : /trojan-ws"
echo -e "ServiceName  : trojan-grpc"
echo -e "Status       : $api_status"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Link TLS     : $trojanlink1"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Link NTLS    : $trojanlink2"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Link GRPC    : $trojanlink3"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
} | tee -a "$LOG_FILE"

echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu-trojan 2>/dev/null || menu
