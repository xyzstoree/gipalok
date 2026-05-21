#!/bin/bash
# ============================================================================
# v7fix — list active Trojan users
# ============================================================================

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

CONFIG="/etc/xray/config.json"
ACCESS_LOG="/var/log/xray/access.log"
EXPIRY_DIR="/etc/Anggun/Expiry/trojan"

clear
echo -e "${CYAN:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"
echo -e "         TROJAN USER LOGIN"
echo -e "${CYAN:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"

if [ ! -f "$CONFIG" ]; then
    fail "Xray config tidak ditemukan."
    v7_pause_back menu-trojan
    exit 1
fi

mapfile -t USERS < <(
    jq -r '
      .inbounds[]?
      | select(.tag=="trojan-ws" or .tag=="trojan-grpc")
      | .settings.clients[]?.email // empty
    ' "$CONFIG" 2>/dev/null | sort -u
)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "Belum ada user Trojan."
    v7_pause_back menu-trojan
    exit 0
fi

printf "%-22s %-12s %-30s\n" "USER" "EXP" "ONLINE IPs (last 500 log lines)"
echo -e "${CYAN:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"

for user in "${USERS[@]}"; do
    exp="-"
    [ -f "$EXPIRY_DIR/$user" ] && exp="$(cat "$EXPIRY_DIR/$user" 2>/dev/null)"

    ips="-"
    if [ -f "$ACCESS_LOG" ]; then
        ips=$(tail -n 500 "$ACCESS_LOG" 2>/dev/null \
              | grep -E "email:[[:space:]]*${user}[[:space:]]*\$" \
              | awk '{for(i=1;i<=NF;i++) if($i~/^tcp:|^[0-9]+\./) {print $i; break}}' \
              | sed 's/tcp://; s/:[0-9]*$//' \
              | sort -u | head -5 | tr '\n' ',' | sed 's/,$//')
        [ -z "$ips" ] && ips="-"
    fi

    printf "%-22s %-12s %-30s\n" "$user" "$exp" "$ips"
done

echo -e "${CYAN:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"
echo "Total: ${#USERS[@]} user"

v7_pause_back menu-trojan
