#!/bin/bash
set -e

clear

CONFIG="/etc/xray/config.json"
XRAY_BIN="$(command -v xray || echo /usr/local/bin/xray)"
QUEUE_DIR="/etc/Anggun/Queue/vless"
EXPIRY_DIR="/etc/Anggun/Expiry/vless"
LOG_FILE="/etc/log-create-user.log"

mkdir -p "$QUEUE_DIR/ip" "$QUEUE_DIR/quota" "$EXPIRY_DIR" /etc/Anggun
touch "$LOG_FILE"

source /var/lib/Anggun/ipvps.conf 2>/dev/null || true

domain=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || echo "-")
bug="${IP:-$domain}"

tls="$(grep -w "Vless TLS" ~/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"
none="$(grep -w "Vless None TLS" ~/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"

[ -z "$tls" ] && tls="443"
[ -z "$none" ] && none="80"

schedule_cleaner() {
    local user="$1"
    local exp="$2"
    local cleaner="/usr/local/bin/clean-vless-${user}.sh"
    local delete_time

    delete_time=$(date -d "$exp" +"%H:%M %Y-%m-%d")

    for job in $(atq 2>/dev/null | awk '{print $1}'); do
        at -c "$job" 2>/dev/null | grep -q "$cleaner" && atrm "$job" 2>/dev/null || true
    done

    cat > "$cleaner" <<CLEANER_SCRIPT
#!/bin/bash
CONFIG="/etc/xray/config.json"
XRAY_BIN="\$(command -v xray || echo /usr/local/bin/xray)"
USER="$user"
LOG="/var/log/trial-cleaner.log"

echo "\$(date) Cleaning VLess \$USER" >> "\$LOG"

tmp=\$(mktemp --suffix=.json)

jq --arg user "\$USER" '
  .inbounds |= map(
    if (.tag == "vless-ws" or .tag == "vless-grpc") then
      .settings.clients = [ .settings.clients[]? | select(.email != \$user) ]
    else
      .
    end
  )
' "\$CONFIG" > "\$tmp"

if "\$XRAY_BIN" run -test -config "\$tmp" >/dev/null 2>&1; then
    mv "\$tmp" "\$CONFIG"
    systemctl restart xray >/dev/null 2>&1 || true
    echo "\$(date) Cleaned VLess \$USER OK" >> "\$LOG"
else
    rm -f "\$tmp"
    echo "\$(date) Cleaned VLess \$USER FAILED config invalid" >> "\$LOG"
fi

rm -f /etc/Anggun/Queue/vless/ip/\$USER /etc/Anggun/Queue/vless/quota/\$USER
rm -f /etc/Anggun/Expiry/vless/\$USER
rm -f /etc/Anggun/Usage/vless/\$USER
rm -f /etc/Anggun/vless/\$USER /etc/Anggun/cache/vless-ws/\$USER
rm -f "$cleaner"
CLEANER_SCRIPT

    chmod +x "$cleaner"

    if ! command -v at >/dev/null 2>&1; then
        apt install -y at >/dev/null 2>&1 || true
        systemctl enable --now atd >/dev/null 2>&1 || true
    fi

    echo "$cleaner" | at "$delete_time" >/dev/null 2>&1 || true
}

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m        CREATE VLESS ACCOUNT        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
read -rp "Username      : " user
read -rp "Expired Days  : " masaaktif
read -rp "Limit IP      : " iplimit
read -rp "Quota GB      : " quota

if [ -z "$user" ]; then
    echo "Username tidak boleh kosong."
    sleep 2
    menu-vless 2>/dev/null || menu
    exit 1
fi

if ! echo "$user" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "Username hanya boleh huruf, angka, _ dan -"
    sleep 2
    menu-vless 2>/dev/null || menu
    exit 1
fi

[ -z "$masaaktif" ] && masaaktif="30"
[ -z "$iplimit" ] && iplimit="2"
[ -z "$quota" ] && quota="0"

if ! echo "$masaaktif" | grep -Eq '^[0-9]+$'; then
    echo "Expired harus angka hari. Contoh: 30"
    sleep 2
    menu-vless 2>/dev/null || menu
    exit 1
fi

if ! echo "$iplimit" | grep -Eq '^[0-9]+$'; then
    iplimit="2"
fi

if ! echo "$quota" | grep -Eq '^[0-9]+$'; then
    quota="0"
fi

exp="$(date -d "+$masaaktif days" +"%Y-%m-%d %H:%M:%S")"

# DIRECT_SAVE_EXPIRY_RECORD_START
mkdir -p "$EXPIRY_DIR"
echo "$exp" > "$EXPIRY_DIR/$user"
# DIRECT_SAVE_EXPIRY_RECORD_END
uuid=$(cat /proc/sys/kernel/random/uuid)
quota_bytes=$((quota * 1024 * 1024 * 1024))

if jq --arg user "$user" '[.inbounds[]?.settings.clients[]? | select(.email==$user)] | length' "$CONFIG" | grep -qv '^0$'; then
    echo "User sudah ada."
    sleep 2
    menu-vless 2>/dev/null || menu
    exit 1
fi

backup="${CONFIG}.bak.$(date +%s)"
cp "$CONFIG" "$backup"

tmp=$(mktemp --suffix=.json)

jq --arg user "$user" --arg uuid "$uuid" '
  .inbounds |= map(
    if (.tag == "vless-ws" or .tag == "vless-grpc") then
      .settings.clients = ((.settings.clients // []) + [{"id": $uuid, "email": $user}])
    else
      .
    end
  )
' "$CONFIG" > "$tmp"

if ! TEST_OUT=$("$XRAY_BIN" run -test -config "$tmp" 2>&1); then
    rm -f "$tmp"
    echo ""
    echo "[ERROR] Config Xray tidak valid. Akun batal dibuat."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$TEST_OUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    sleep 5
    menu-vless 2>/dev/null || menu
    exit 1
fi

mv "$tmp" "$CONFIG"

if systemctl restart xray >/dev/null 2>&1; then
    api_status="Created, Xray restarted"
else
    cp "$backup" "$CONFIG"
    systemctl restart xray >/dev/null 2>&1 || true
    echo "[ERROR] Gagal restart Xray. Akun batal dibuat."
    sleep 3
    menu-vless 2>/dev/null || menu
    exit 1
fi

echo "$exp" > "$EXPIRY_DIR/$user"

[ "$iplimit" -gt 0 ] && echo "$iplimit" > "$QUEUE_DIR/ip/$user"
[ "$quota" -gt 0 ] && echo "$quota_bytes" > "$QUEUE_DIR/quota/$user"

schedule_cleaner "$user" "$exp"

vlesslink1="vless://${uuid}@${bug}:${tls}?path=%2Fvless&security=tls&encryption=none&type=ws&host=${domain}&sni=${domain}#${user}"
vlesslink2="vless://${uuid}@${bug}:${none}?path=%2Fvless&security=none&encryption=none&type=ws&host=${domain}#${user}"
vlesslink3="vless://${uuid}@${bug}:${tls}?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}"

clear
{
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "\E[0;41;36m           VLess Account            \E[0m"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Remarks      : $user"
echo -e "Address/Bug  : $bug"
echo -e "Host/SNI     : $domain"
echo -e "Port TLS     : $tls"
echo -e "Port NTLS    : $none"
echo -e "UUID         : $uuid"
echo -e "Expired      : $exp"
echo -e "Limit IP     : $iplimit"
echo -e "Quota        : $quota GB"
echo -e "Network      : ws/grpc"
echo -e "Path         : /vless"
echo -e "ServiceName  : vless-grpc"
echo -e "Status       : $api_status"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Link TLS     : $vlesslink1"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Link NTLS    : $vlesslink2"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Link GRPC    : $vlesslink3"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
} | tee -a "$LOG_FILE"

echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu-vless 2>/dev/null || menu
