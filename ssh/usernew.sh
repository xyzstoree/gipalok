#!/bin/bash
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=$(date +"%Y-%m-%d" -d "$dateFromServer")

mkdir -p /etc/Anggun/Queue/ssh/ip
mkdir -p /var/lib/Anggun
touch /root/log-install.txt

clear
cekray=$(cat /root/log-install.txt | grep -ow "XRAY" | sort | uniq)
domen=$(cat /etc/xray/domain 2>/dev/null)

portsshws=$(cat /root/log-install.txt | grep -w "SSH Websocket" | cut -d: -f2 | awk '{print $1}')
wsssl=$(cat /root/log-install.txt | grep -w "SSH SSL Websocket" | cut -d: -f2 | awk '{print $1}')
opensh=$(cat /root/log-install.txt | grep -w "OpenSSH" | cut -f2 -d: | awk '{print $1}')
db=$(cat /root/log-install.txt | grep -w "Dropbear" | cut -f2 -d: | awk '{print $1,$2}')
ssl="$(cat /root/log-install.txt | grep -w "Stunnel4" | cut -d: -f2)"
sqd="$(cat /root/log-install.txt | grep -w "Squid" | cut -d: -f2)"

[ -z "$portsshws" ] && portsshws="80"
[ -z "$wsssl" ] && wsssl="443"
[ -z "$opensh" ] && opensh="22"
[ -z "$db" ] && db="109, 143"
[ -z "$ssl" ] && ssl=" 447, 777"

IP=$(curl -sS ifconfig.me 2>/dev/null || curl -sS ipinfo.io/ip 2>/dev/null)
sldomain=$(cat /etc/xray/dns 2>/dev/null || echo "$domen")
slkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "-")

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m            SSH Account            \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username    : " Login
read -p "Password    : " Pass
read -p "Max Login   : " ipQueue
read -p "Expired (Days): " masaaktif

[ -z "$Login" ] && { echo "Username tidak boleh kosong!"; sleep 2; menu-ssh; exit; }
[ -z "$Pass" ] && { echo "Password tidak boleh kosong!"; sleep 2; menu-ssh; exit; }
[ -z "$masaaktif" ] && masaaktif=30
[ -z "$ipQueue" ] && ipQueue=2

sleep 1
clear

expdate=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Buat/update user SSH dengan shell valid agar OpenSSH/Dropbear tidak langsung menutup koneksi.
if id "$Login" >/dev/null 2>&1; then
    usermod -e "$expdate" -s /bin/bash "$Login"
else
    useradd -e "$expdate" -s /bin/bash -m "$Login"
fi

mkdir -p "/home/$Login"
chown "$Login:$Login" "/home/$Login"
chmod 755 "/home/$Login"

grep -qxF /bin/bash /etc/shells || echo /bin/bash >> /etc/shells

echo "$Login:$Pass" | chpasswd
chage -M 99999 "$Login"

exp="$(chage -l "$Login" | grep "Account expires" | awk -F": " '{print $2}')"

if [[ $ipQueue -gt 0 ]]; then
    echo -e "$ipQueue" > /etc/Anggun/Queue/ssh/ip/$Login
fi

echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m" | tee -a /etc/log-create-user.log
echo -e "\E[0;41;36m              SSH Account Info              \E[0m" | tee -a /etc/log-create-user.log
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m" | tee -a /etc/log-create-user.log
echo -e "Username    : $Login" | tee -a /etc/log-create-user.log
echo -e "Password    : $Pass" | tee -a /etc/log-create-user.log
echo -e "Max Login   : $ipQueue" | tee -a /etc/log-create-user.log
echo -e "Expired On  : $exp" | tee -a /etc/log-create-user.log
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m" | tee -a /etc/log-create-user.log
echo -e "IP VPS      : $IP" | tee -a /etc/log-create-user.log
echo -e "Host        : $domen" | tee -a /etc/log-create-user.log
echo -e "OpenSSH     : $opensh" | tee -a /etc/log-create-user.log
echo -e "Dropbear    : $db" | tee -a /etc/log-create-user.log
echo -e "SSH-WS      : $portsshws" | tee -a /etc/log-create-user.log
echo -e "SSH-SSL-WS  : $wsssl" | tee -a /etc/log-create-user.log
echo -e "SSL/TLS     :$ssl" | tee -a /etc/log-create-user.log
echo -e "UDP         : 1-65535" | tee -a /etc/log-create-user.log
echo -e "UDPGW       : 7100-7900" | tee -a /etc/log-create-user.log
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m" | tee -a /etc/log-create-user.log
echo -e "Payload WS  : GET / HTTP/1.1[crlf]Host: $domen[crlf]Connection: Upgrade[crlf]Upgrade: websocket[crlf][crlf]" | tee -a /etc/log-create-user.log
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◇\033[0m" | tee -a /etc/log-create-user.log
echo "" | tee -a /etc/log-create-user.log
read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
menu-ssh
