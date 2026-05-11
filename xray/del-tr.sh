#!/bin/bash
set -e

CONFIG="/etc/xray/config.json"
XRAY_BIN="$(command -v xray || echo /usr/local/bin/xray)"
EXPIRY_DIR="/etc/Anggun/Expiry/trojan"

mkdir -p "$EXPIRY_DIR"

back_menu() {
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-trojan 2>/dev/null || menu
}

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "        DELETE Trojan ACCOUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mapfile -t USERS < <(
    jq -r '
      .inbounds[]?
      | select(.tag=="trojan-ws" or .tag=="trojan-grpc")
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

tmp=$(mktemp --suffix=.json)

jq --arg user "$user" '
  .inbounds |= map(
    if (.tag == "trojan-ws" or .tag == "trojan-grpc") then
      .settings.clients = [ .settings.clients[]? | select(.email != $user) ]
    else
      .
    end
  )
' "$CONFIG" > "$tmp"

if ! "$XRAY_BIN" run -test -config "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    echo "Config Xray tidak valid. Delete dibatalkan."
    sleep 2
    back_menu
    exit 1
fi

mv "$tmp" "$CONFIG"

for job in $(atq 2>/dev/null | awk '{print $1}'); do
    at -c "$job" 2>/dev/null | grep -q "/usr/local/bin/clean-trojan-${user}.sh" && atrm "$job" 2>/dev/null || true
done

rm -f "/usr/local/bin/clean-trojan-${user}.sh"
rm -f /etc/Anggun/Queue/trojan/ip/"$user" /etc/Anggun/Queue/trojan/quota/"$user"
rm -f /etc/Anggun/Expiry/trojan/"$user"
rm -f /etc/Anggun/Usage/trojan/"$user"
rm -f /etc/Anggun/trojan/"$user" /etc/Anggun/cache/trojan-ws/"$user"

systemctl restart xray >/dev/null 2>&1 || true

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Delete Trojan Berhasil"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Username : $user"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

back_menu
