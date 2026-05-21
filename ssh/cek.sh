#!/bin/bash
# ============================================================================
# v7fix — check SSH/OpenVPN logged-in users
# Fixes vs gipalok:
#   - Removed dead code (curl google for date)
#   - Use mapfile/array instead of subshell + ps grep gymnastics
#   - Tolerate missing log files (auth.log vs secure)
#   - Remove stale tmp files even on error
# ============================================================================

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

clear
echo

# Resolve auth log path
LOG=""
[ -e /var/log/auth.log ] && LOG="/var/log/auth.log"
[ -e /var/log/secure ]   && LOG="/var/log/secure"

cleanup() { rm -f /tmp/login-db.txt /tmp/login-db-pid.txt /tmp/vpn-login-tcp.txt /tmp/vpn-login-udp.txt; }
trap cleanup EXIT

# ----------- Dropbear -----------
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m         Dropbear User Login        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo "ID  |  Username  |  IP Address"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
if [ -n "$LOG" ]; then
    grep -i dropbear "$LOG" 2>/dev/null | grep -i "Password auth succeeded" > /tmp/login-db.txt
    while read -r PID; do
        [ -z "$PID" ] && continue
        line=$(grep "dropbear\[$PID\]" /tmp/login-db.txt | tail -n1)
        [ -z "$line" ] && continue
        USER=$(echo "$line" | awk '{print $10}')
        IP=$(echo   "$line" | awk '{print $12}')
        echo "$PID - $USER - $IP"
    done < <(pgrep -x dropbear 2>/dev/null)
else
    echo "  (auth.log/secure tidak ditemukan)"
fi
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo
# ----------- OpenSSH -----------
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m          OpenSSH User Login        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo "ID  |  Username  |  IP Address"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
if [ -n "$LOG" ]; then
    grep -i sshd "$LOG" 2>/dev/null | grep -i "Accepted password for" > /tmp/login-db.txt
    while read -r PID; do
        [ -z "$PID" ] && continue
        line=$(grep "sshd\[$PID\]" /tmp/login-db.txt | tail -n1)
        [ -z "$line" ] && continue
        USER=$(echo "$line" | awk '{print $9}')
        IP=$(echo   "$line" | awk '{print $11}')
        echo "$PID - $USER - $IP"
    done < <(ps aux 2>/dev/null | awk '/sshd:.*\[priv\]/ {print $2}')
else
    echo "  (auth.log/secure tidak ditemukan)"
fi
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# ----------- OpenVPN TCP -----------
if [ -f /etc/openvpn/server/openvpn-tcp.log ]; then
    echo
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;41;36m          OpenVPN TCP User Login         \E[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo "Username  |  IP Address  |  Connected Since"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    grep -w "^CLIENT_LIST" /etc/openvpn/server/openvpn-tcp.log \
        | cut -d',' -f2,3,8 | sed -e 's/,/      /g'
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
fi

# ----------- OpenVPN UDP -----------
if [ -f /etc/openvpn/server/openvpn-udp.log ]; then
    echo
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;41;36m          OpenVPN UDP User Login         \E[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo "Username  |  IP Address  |  Connected Since"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    grep -w "^CLIENT_LIST" /etc/openvpn/server/openvpn-udp.log \
        | cut -d',' -f2,3,8 | sed -e 's/,/      /g'
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
fi

echo
read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
menu-ssh 2>/dev/null || menu
