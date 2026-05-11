#!/bin/bash
# Queue-ip-ssh.sh — Fixed
# FIX 1: Original called mesinssh (reads auth.log) and counted log lines — unreliable.
#         Now uses `who` which shows active sessions and their source IPs accurately.
# FIX 2: Original used `userdel -f -r $user` — PERMANENTLY deletes the account!
#         Fixed to `pkill -u` (kick session only, account preserved).
# FIX 3: telegram-send may not be installed — now uses tg_send from lib-telegram.
# FIX 4: nais was used outside loop but never initialized — added initialization.
source /etc/Queue/lib-telegram.sh 2>/dev/null || true
nais=0
data=( $(ls /etc/Anggun/Queue/ssh/ip 2>/dev/null) )
for user in "${data[@]}"; do
    [ -f "/etc/Anggun/Queue/ssh/ip/$user" ] || continue
    ipQueue=$(cat "/etc/Anggun/Queue/ssh/ip/$user" 2>/dev/null || echo 0)
    [ "${ipQueue:-0}" -lt 1 ] && continue

    # FIX: Use `who` to get unique source IPs for this user
    # `ss -tnp` does not show usernames — grep would never match
    ehh=$(who 2>/dev/null | awk -v u="$user" '$1==u { gsub(/[()]/,"",$5); if($5~/[0-9]/) print $5 }' | sort | uniq)
    cekcek=$(echo "$ehh" | grep -c '[0-9]' 2>/dev/null || echo 0)

    if [[ "$cekcek" -gt "$ipQueue" ]]; then
        # FIX: pkill only kicks the session; original userdel -f -r deleted the account permanently
        pkill -u "$user" -KILL 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') | SSH | $user | limit=$ipQueue aktif=$cekcek" >> /root/log-limit.txt
        nais=3
        declare -f tg_send >/dev/null 2>&1 && \
            tg_send "⚠️ *[SSH IP Limit]* User *${user}* melebihi limit *${ipQueue}* IP (aktif: ${cekcek}). Sesi di-kick."
    fi
    sleep 0.1
done
