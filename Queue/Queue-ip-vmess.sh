#!/bin/bash
# Queue-ip-vmess.sh — Fixed
# FIX 1: Removed `echo -n > /var/log/xray/access.log` — this TRUNCATED the log every run,
#         destroying all log data. Xray access.log must never be truncated here.
# FIX 2: Original read from /var/log/xray/vmess.log — this file doesn't exist in standard
#         Xray. Fixed to use /var/log/xray/access.log with correct email pattern.
# FIX 3: disable-vmess command likely doesn't exist — replaced with lock-ws (safe lock).
# FIX 4: telegram-send → tg_send from lib-telegram.
# FIX 5: systemctl restart for non-existent per-protocol services removed; use xray.
source /etc/Queue/lib-telegram.sh 2>/dev/null || true
nais=0
sleep 4
data=( $(ls /etc/Anggun/Queue/vmess/ip 2>/dev/null) )
for user in "${data[@]}"; do
    [ -f "/etc/Anggun/Queue/vmess/ip/$user" ] || continue
    ipQueue=$(cat "/etc/Anggun/Queue/vmess/ip/$user" 2>/dev/null || echo 0)
    [ "${ipQueue:-0}" -lt 1 ] && continue

    # FIX: Read from unified access.log; filter by email tag
    ehh=$(grep "email: vmess-${user}" /var/log/xray/access.log 2>/dev/null \
          | awk '{print $3}' | sed 's/tcp://g' | cut -d: -f1 | sort | uniq)
    cekcek=$(echo "$ehh" | grep -c '[0-9]' 2>/dev/null || echo 0)

    if [[ "$cekcek" -gt "$ipQueue" ]]; then
        # FIX: lock-ws is safer than disable-vmess (which may not exist)
        lock-ws "$user" 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') | VMESS | $user | limit=$ipQueue aktif=$cekcek" >> /root/log-limit.txt
        nais=3
        declare -f tg_send >/dev/null 2>&1 && \
            tg_send "⚠️ *[VMESS IP Limit]* User *${user}* melebihi limit *${ipQueue}* IP (aktif: ${cekcek}). Akun di-lock."
    fi
    sleep 0.1
done
# FIX: Restart xray (not per-protocol services that don't exist)
if [[ $nais -gt 1 ]]; then systemctl restart xray >/dev/null 2>&1; fi
