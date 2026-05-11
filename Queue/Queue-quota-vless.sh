#!/bin/bash
# Queue-quota-vless.sh — Fixed
# FIX 1: `sed -i "/$user/d" /etc/xray/vless*` → jq-based safe removal
# FIX 2: `rm /etc/Anggun/cache/*/$user` → explicit paths
# FIX 3: systemctl restart vless-ws/vless-grpc → systemctl restart xray
nais=0
for quota_file in /etc/Anggun/Queue/vless/quota/*; do
    [ -f "$quota_file" ] || continue
    user=$(basename "$quota_file")
    limit=$(cat "$quota_file" 2>/dev/null || echo 0)
    used=$(cat "/etc/Anggun/vless/$user" 2>/dev/null || echo 0)
    if [[ "$used" -gt "$limit" ]]; then
        tmp=$(mktemp)
        jq --arg u "$user" '
          .inbounds |= map(
            if (.settings.clients? // null) != null then
              .settings.clients |= map(
                select(.email != ("vless-"+$u) and .email != ("#!vless-"+$u))
              )
            else . end
          )
        ' /etc/xray/config.json > "$tmp" && mv "$tmp" /etc/xray/config.json
        rm -f "/etc/Anggun/vless/$user"
        rm -f "/etc/Anggun/Queue/vless/quota/$user"
        rm -f "/etc/Anggun/Queue/vless/ip/$user"
        rm -f "/etc/Anggun/Expiry/vless/$user"
        rm -f "/etc/Anggun/cache/vless-ws/$user"
        rm -f "/etc/Anggun/cache/vless-grpc/$user"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | VLESS-QUOTA | $user | used=$used limit=$limit" >> /root/log-limit.txt
        nais=3
    fi
    sleep 0.1
done
[[ $nais -gt 1 ]] && systemctl restart xray >/dev/null 2>&1
