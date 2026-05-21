#!/bin/bash
# ============================================================================
# v7fix — Trial SSH Account with duration input: 3h / 3d
# ============================================================================
# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

clear

domain=$(v7_get_domain 2>/dev/null || cat /etc/xray/domain 2>/dev/null || echo "-")
IP=$(v7_get_ip 2>/dev/null || echo "-")

mkdir -p /etc/Anggun/Queue/ssh/ip
touch /root/log-install.txt
touch /etc/log-create-user.log

clear
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "\E[0;41;36m          Trial SSH Account         \E[0m"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo ""
echo "Format durasi:"
echo "  3h = 3 jam"
echo "  3d = 3 hari"
echo ""
read -rp "Durasi Trial : " duration
read -rp "Limit IP     : " iplimit

[ -z "$duration" ] && duration="1d"
[ -z "$iplimit" ] && iplimit="2"

if ! echo "$duration" | grep -Eq '^[0-9]+[hHdD]$'; then
    echo ""
    echo "Format durasi salah. Contoh yang benar: 3h atau 3d"
    sleep 2
    menu-ssh 2>/dev/null || menu
    exit 1
fi

num=$(echo "$duration" | sed 's/[^0-9]//g')
unit=$(echo "$duration" | sed 's/[0-9]//g' | tr 'A-Z' 'a-z')

if [ "$num" -lt 1 ]; then
    echo ""
    echo "Durasi minimal 1."
    sleep 2
    menu-ssh 2>/dev/null || menu
    exit 1
fi

Login="Trial-$(tr -dc 'A-Z0-9' </dev/urandom | head -c 4)"
Pass="$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 8)"

if [ "$unit" = "h" ]; then
    exp_date=$(date -d "+1 day" +"%Y-%m-%d")
    exp_display=$(date -d "+$num hours" +"%Y-%m-%d %H:%M:%S")
    delete_time=$(date -d "+$num hours" +"%H:%M %Y-%m-%d")
    duration_text="$num Jam"
elif [ "$unit" = "d" ]; then
    exp_date=$(date -d "+$num days" +"%Y-%m-%d")
    exp_display=$(date -d "+$num days" +"%Y-%m-%d %H:%M:%S")
    delete_time=$(date -d "+$num days" +"%H:%M %Y-%m-%d")
    duration_text="$num Hari"
else
    echo ""
    echo "Unit durasi tidak valid."
    sleep 2
    menu-ssh 2>/dev/null || menu
    exit 1
fi

# Buat user SSH
if id "$Login" >/dev/null 2>&1; then
    userdel -f "$Login" >/dev/null 2>&1 || true
fi

useradd -e "$exp_date" -s /bin/bash -M "$Login"

if ! echo "$Login:$Pass" | chpasswd >/dev/null 2>&1; then
    echo "Gagal set password untuk $Login"
    userdel -f "$Login" >/dev/null 2>&1 || true
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-ssh 2>/dev/null || menu
    exit 1
fi

# Limit IP
if [[ "$iplimit" =~ ^[0-9]+$ ]] && [ "$iplimit" -gt 0 ]; then
    echo "$iplimit" > "/etc/Anggun/Queue/ssh/ip/$Login"
else
    iplimit="2"
    echo "$iplimit" > "/etc/Anggun/Queue/ssh/ip/$Login"
fi

# Jadwalkan hapus user untuk durasi jam/hari yang presisi
delete_cmd="/usr/sbin/userdel -f $Login >/dev/null 2>&1; rm -f /etc/Anggun/Queue/ssh/ip/$Login >/dev/null 2>&1"

if command -v at >/dev/null 2>&1; then
    echo "$delete_cmd" | at "$delete_time" >/dev/null 2>&1
else
    apt install -y at >/dev/null 2>&1 || true
    systemctl enable --now atd >/dev/null 2>&1 || true
    if command -v at >/dev/null 2>&1; then
        echo "$delete_cmd" | at "$delete_time" >/dev/null 2>&1
    else
        # fallback cron kalau at gagal
        cron_file="/etc/cron.d/trial-$Login"
        del_min=$(date -d "$exp_display" +"%M")
        del_hour=$(date -d "$exp_display" +"%H")
        del_day=$(date -d "$exp_display" +"%d")
        del_month=$(date -d "$exp_display" +"%m")
        echo "$del_min $del_hour $del_day $del_month * root $delete_cmd; rm -f $cron_file" > "$cron_file"
        chmod 644 "$cron_file"
    fi
fi

clear
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "\E[0;41;36m             Trial SSH              \E[0m"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Username     : $Login"
echo -e "Password     : $Pass"
echo -e "Durasi       : $duration_text"
echo -e "Expired      : $exp_display"
echo -e "Limit IP     : $iplimit"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "IP           : $IP"
echo -e "Host         : $domain"
echo -e "OpenSSH      : 22"
echo -e "Dropbear     : 109, 110, 143"
echo -e "SSH WS NTLS  : 80, 8080, 8880, 2082, 2086"
echo -e "SSH WS TLS   : 443"
echo -e "SSL/TLS      : 443, 777"
echo -e "UDPGW        : 7100-7900"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "SSH-80       : ${domain}:80@$Login:$Pass"
echo -e "SSH-443      : ${domain}:443@$Login:$Pass"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Payload Websocket:"
echo -e "GET / HTTP/1.1[crlf]Host: [host][crlf]Connection: Upgrade[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"

{
echo "Trial SSH"
echo "Username : $Login"
echo "Password : $Pass"
echo "Durasi   : $duration_text"
echo "Expired  : $exp_display"
echo "Limit IP : $iplimit"
echo "Host     : $domain"
echo "Created  : $(date)"
echo "━━━━━━━━━━━━━━━━━━━━"
} >> /etc/log-create-user.log

echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu-ssh 2>/dev/null || menu
