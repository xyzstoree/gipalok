#!/bin/bash
# Queue-ip-vless.sh — Fixed (same fixes as Queue-ip-vmess.sh)
# FIX 1: Removed echo -n > /var/log/xray/access.log (log truncation)
# FIX 2: Read from access.log not from non-existent vless.log
# FIX 3: disable-vless → lock-vless
# FIX 4: telegram-send → tg_send from lib-telegram
# FIX 5: Restart xray (not per-protocol services)
source /etc/Queue/lib-telegram.sh 2>/dev/null || true
nais=0
sleep 4
data=( $(ls /etc/Anggun/Queue/vless/ip 2>/dev/null) )
for user in "${data[@]}"; do
    [ -f "/etc/Anggun/Queue/vless/ip/$user" ] || continue
    ipQueue=$(cat "/etc/Anggun/Queue/vless/ip/$user" 2>/dev/null || echo 0)
    [ "${ipQueue:-0}" -lt 1 ] && continue

    ehh=$(grep "email: vless-${user}" /var/log/xray/access.log 2>/dev/null \
          | awk '{print $3}' | sed 's/tcp://g' | cut -d: -f1 | sort | uniq)
    cekcek=$(echo "$ehh" | grep -c '[0-9]' 2>/dev/null || echo 0)

    if [[ "$cekcek" -gt "$ipQueue" ]]; then
        lock-vless "$user" 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') | VLESS | $user | limit=$ipQueue aktif=$cekcek" >> /root/log-limit.txt
        nais=3
        declare -f tg_send >/dev/null 2>&1 && \
            tg_send "⚠️ *[VLESS IP Limit]* User *${user}* melebihi limit *${ipQueue}* IP (aktif: ${cekcek}). Akun di-lock."
    fi
    sleep 0.1
done
if [[ $nais -gt 1 ]]; then systemctl restart xray >/dev/null 2>&1; fi
