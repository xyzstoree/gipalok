#!/bin/bash
# ============================================================================
# v7fix — create SSH/OpenVPN account
# Fixes vs gipalok:
#   - Removed dead code (curl google for date)
#   - Username validation
#   - Idempotent (handle existing user safely)
#   - Use lib/common.sh helpers
# ============================================================================

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

mkdir -p /etc/Anggun/Queue/ssh/ip /var/lib/Anggun
touch /root/log-install.txt

domen=$(v7_get_domain 2>/dev/null || cat /etc/xray/domain 2>/dev/null || echo "-")
IP=$(v7_get_ip 2>/dev/null || echo "-")

# Read installed ports (with sane defaults)
portsshws=$(grep -w "SSH Websocket"     /root/log-install.txt 2>/dev/null | cut -d: -f2 | awk '{print $1}')
wsssl=$(grep -w "SSH SSL Websocket"     /root/log-install.txt 2>/dev/null | cut -d: -f2 | awk '{print $1}')
opensh=$(grep -w "OpenSSH"              /root/log-install.txt 2>/dev/null | cut -d: -f2 | awk '{print $1}')
db=$(grep -w "Dropbear"                 /root/log-install.txt 2>/dev/null | cut -d: -f2 | awk '{print $1,$2}')
ssl=$(grep -w "Stunnel4"                /root/log-install.txt 2>/dev/null | cut -d: -f2)

[ -z "$portsshws" ] && portsshws="80"
[ -z "$wsssl" ]     && wsssl="443"
[ -z "$opensh" ]    && opensh="22"
[ -z "$db" ]        && db="109, 143"
[ -z "$ssl" ]       && ssl=" 447, 777"

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m            SSH Account             \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -rp "Username      : " Login
read -rp "Password      : " Pass
read -rp "Max Login     : " ipQueue
read -rp "Expired (Days): " masaaktif

# ---------- Validate ----------
if [ -z "$Login" ]; then
    fail "Username tidak boleh kosong!"; sleep 2; menu-ssh; exit 1
fi
if ! v7_valid_username "$Login"; then
    fail "Username harus 2-32 karakter, hanya [a-zA-Z0-9_-], diawali huruf/angka/_."
    sleep 3; menu-ssh; exit 1
fi
if [ -z "$Pass" ]; then
    fail "Password tidak boleh kosong!"; sleep 2; menu-ssh; exit 1
fi
[ -z "$masaaktif" ] && masaaktif=30
[ -z "$ipQueue" ]   && ipQueue=2
v7_valid_int "$masaaktif" || masaaktif=30
v7_valid_int "$ipQueue"   || ipQueue=2

sleep 1
clear

expdate=$(date -d "+$masaaktif days" +"%Y-%m-%d")

# ---------- Create / update user ----------
# Use a real shell so OpenSSH/Dropbear sessions stay open.
if id "$Login" >/dev/null 2>&1; then
    usermod -e "$expdate" -s /bin/bash "$Login"
else
    useradd -e "$expdate" -s /bin/bash -m "$Login"
fi

# Make sure home dir exists with correct perms even if useradd skipped it
mkdir -p "/home/$Login"
chown "$Login:$Login" "/home/$Login"
chmod 755 "/home/$Login"

grep -qxF /bin/bash /etc/shells || echo /bin/bash >> /etc/shells

echo "$Login:$Pass" | chpasswd
chage -M 99999 "$Login"

# Persist limit IP
if [ "$ipQueue" -gt 0 ]; then
    echo "$ipQueue" > "/etc/Anggun/Queue/ssh/ip/$Login"
fi

exp="$(chage -l "$Login" | grep "Account expires" | awk -F": " '{print $2}')"

# ---------- Display ----------
{
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "\E[0;41;36m              SSH Account Info              \E[0m"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Username    : $Login"
echo -e "Password    : $Pass"
echo -e "Max Login   : $ipQueue"
echo -e "Expired On  : $exp"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "IP VPS      : $IP"
echo -e "Host        : $domen"
echo -e "OpenSSH     : $opensh"
echo -e "Dropbear    : $db"
echo -e "SSH-WS      : $portsshws"
echo -e "SSH-SSL-WS  : $wsssl"
echo -e "SSL/TLS     :$ssl"
echo -e "UDP         : 1-65535"
echo -e "UDPGW       : 7100-7900"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Payload WS  : GET / HTTP/1.1[crlf]Host: $domen[crlf]Connection: Upgrade[crlf]Upgrade: websocket[crlf][crlf]"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m"
echo ""
} | tee -a /etc/log-create-user.log

read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
menu-ssh
