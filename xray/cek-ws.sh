#!/bin/bash
# ============================================================================
# v7fix — list active VMess users (online)
# Fixes vs gipalok: original parsed `###` markers from config — those don't
# exist in jq-based config. Now we read the actual clients[].email field
# and cross-check with xray access.log.
# ============================================================================

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

CONFIG="/etc/xray/config.json"
ACCESS_LOG="/var/log/xray/access.log"
EXPIRY_DIR="/etc/Anggun/Expiry/vmess"

clear
echo -e "${CYAN:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"
echo -e "         VMESS USER LOGIN"
echo -e "${CYAN:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"

if [ ! -f "$CONFIG" ]; then
    fail "Xray config tidak ditemukan."
    v7_pause_back menu-vmess
    exit 1
fi

mapfile -t USERS < <(
    jq -r '
      .inbounds[]?
      | select(.tag=="vmess-ws" or .tag=="vmess-grpc")
      | .settings.clients[]?.email // empty
    ' "$CONFIG" 2>/dev/null | sort -u
)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "Belum ada user VMess."
    v7_pause_back menu-vmess
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

v7_pause_back menu-vmess
