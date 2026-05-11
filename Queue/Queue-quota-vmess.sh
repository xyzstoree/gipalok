#!/bin/bash
# Queue-quota-vmess.sh — Fixed
# FIX 1: `sed -i "/$user/d" /etc/xray/vmess*` — vmess* glob doesn't match anything
#         (Xray uses a single config.json). Sed by username is also fragile and could
#         delete unrelated lines. Fixed to use jq for safe JSON manipulation.
# FIX 2: `rm /etc/Anggun/cache/*/$user` — path glob with * in middle is unreliable.
#         Fixed to explicit paths.
# FIX 3: systemctl restart vmess-ws / vmess-grpc — these per-protocol services don't
#         exist in modern Xray. Fixed to restart xray.
nais=0
for quota_file in /etc/Anggun/Queue/vmess/quota/*; do
    [ -f "$quota_file" ] || continue
    user=$(basename "$quota_file")
    limit=$(cat "$quota_file" 2>/dev/null || echo 0)
    used=$(cat "/etc/Anggun/vmess/$user" 2>/dev/null || echo 0)
    if [[ "$used" -gt "$limit" ]]; then
        tmp=$(mktemp)
        jq --arg u "$user" '
          .inbounds |= map(
            if (.settings.clients? // null) != null then
              .settings.clients |= map(
                select(.email != ("vmess-"+$u) and .email != ("#!vmess-"+$u))
              )
            else . end
          )
        ' /etc/xray/config.json > "$tmp" && mv "$tmp" /etc/xray/config.json
        rm -f "/etc/Anggun/vmess/$user"
        rm -f "/etc/Anggun/Queue/vmess/quota/$user"
        rm -f "/etc/Anggun/Queue/vmess/ip/$user"
        rm -f "/etc/Anggun/Expiry/vmess/$user"
        rm -f "/etc/Anggun/cache/vmess-ws/$user"
        rm -f "/etc/Anggun/cache/vmess-grpc/$user"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | VMESS-QUOTA | $user | used=$used limit=$limit" >> /root/log-limit.txt
        nais=3
    fi
    sleep 0.1
done
[[ $nais -gt 1 ]] && systemctl restart xray >/dev/null 2>&1
