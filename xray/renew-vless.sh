#!/bin/bash
set -e

CONFIG="/etc/xray/config.json"
XRAY_BIN="$(command -v xray || echo /usr/local/bin/xray)"
EXPIRY_DIR="/etc/Anggun/Expiry/vless"

mkdir -p "$EXPIRY_DIR"

back_menu() {
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-vless 2>/dev/null || menu
}

schedule_cleaner() {
    local user="$1"
    local exp="$2"
    local cleaner="/usr/local/bin/clean-vless-${user}.sh"
    local delete_time

    delete_time=$(date -d "$exp" +"%H:%M %Y-%m-%d")

    for job in $(atq 2>/dev/null | awk '{print $1}'); do
        at -c "$job" 2>/dev/null | grep -q "$cleaner" && atrm "$job" 2>/dev/null || true
    done

    cat > "$cleaner" <<CLEANER
#!/bin/bash
CONFIG="/etc/xray/config.json"
XRAY_BIN="\$(command -v xray || echo /usr/local/bin/xray)"
USER="$user"
LOG="/var/log/trial-cleaner.log"

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
    echo "\$(date) Cleaned VLess \$USER FAILED" >> "\$LOG"
fi

rm -f /etc/Anggun/Queue/vless/ip/\$USER /etc/Anggun/Queue/vless/quota/\$USER
rm -f /etc/Anggun/Expiry/vless/\$USER
rm -f /etc/Anggun/Usage/vless/\$USER
rm -f /etc/Anggun/vless/\$USER /etc/Anggun/cache/vless-ws/\$USER
rm -f "$cleaner"
CLEANER

    chmod +x "$cleaner"
    echo "$cleaner" | at "$delete_time" >/dev/null 2>&1 || true
}

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "        RENEW VLess ACCOUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mapfile -t USERS < <(
    jq -r '
      .inbounds[]?
      | select(.tag=="vless-ws" or .tag=="vless-grpc")
      | .settings.clients[]?.email // empty
    ' "$CONFIG" 2>/dev/null | grep -vE '^default-' | sort -u
)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "You have no existing clients!"
    back_menu
    exit 0
fi

printf "%-4s %-25s %-20s\n" "No" "Username" "Expired"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

i=1
for user in "${USERS[@]}"; do
    exp="-"
    [ -f "$EXPIRY_DIR/$user" ] && exp="$(cat "$EXPIRY_DIR/$user")"
    printf "%-4s %-25s %-20s\n" "$i)" "$user" "$exp"
    i=$((i+1))
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -rp "Select user number : " CLIENT_NUMBER

if ! echo "$CLIENT_NUMBER" | grep -Eq '^[0-9]+$' || [ "$CLIENT_NUMBER" -lt 1 ] || [ "$CLIENT_NUMBER" -gt "${#USERS[@]}" ]; then
    echo "Nomor tidak valid."
    sleep 2
    back_menu
    exit 1
fi

user="${USERS[$((CLIENT_NUMBER-1))]}"

echo ""
read -rp "Tambah masa aktif / hari : " masaaktif

[ -z "$masaaktif" ] && masaaktif="30"

if ! echo "$masaaktif" | grep -Eq '^[0-9]+$'; then
    echo "Input harus angka hari. Contoh: 30"
    sleep 2
    back_menu
    exit 1
fi

base="now"

if [ -f "$EXPIRY_DIR/$user" ]; then
    old_exp="$(cat "$EXPIRY_DIR/$user" 2>/dev/null)"
    old_ts="$(date -d "$old_exp" +%s 2>/dev/null || echo 0)"
    now_ts="$(date +%s)"

    if [ "$old_ts" -gt "$now_ts" ]; then
        base="$old_exp"
    fi
fi

new_exp="$(date -d "$base +$masaaktif days" +"%Y-%m-%d %H:%M:%S")"

echo "$new_exp" > "$EXPIRY_DIR/$user"
schedule_cleaner "$user" "$new_exp"

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Renew VLess Berhasil"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Username : $user"
echo "Tambah   : $masaaktif Hari"
echo "Expired  : $new_exp"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

back_menu
