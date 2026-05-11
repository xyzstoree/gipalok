#!/bin/bash
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`

green='\033[0;32m'
red='\033[0;31m'
NC='\033[0m'

mkdir -p /var/lib/Anggun
touch /root/log-install.txt

cekray=`cat /root/log-install.txt | grep -ow "XRAY" | sort | uniq`
if [ "$cekray" = "XRAY" ]; then
    domainlama=`cat /etc/xray/domain`
else
    domainlama=`cat /etc/xray/domain`
fi

clear
echo -e "[ ${green}INFO${NC} ] Start "
sleep 0.5
systemctl stop nginx
systemctl stop xray

domain=$(cat /var/lib/Anggun/ipvps.conf | cut -d'=' -f2)

if [ -z "$domain" ]; then
    echo -e "[ ${red}ERROR${NC} ] Domain belum diset! Jalankan menu > Add Domain dulu."
    read -n 1 -s -r -p "Press any key to back on menu"
    menu
    exit 1
fi

Cek=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
if [[ ! -z "$Cek" ]]; then
    sleep 1
    echo -e "[ ${red}WARNING${NC} ] Detected port 80 used by $Cek "
    systemctl stop $Cek
    sleep 2
    echo -e "[ ${green}INFO${NC} ] Processing to stop $Cek "
    sleep 1
fi

echo -e "[ ${green}INFO${NC} ] Starting renew cert... "
sleep 1

# Install acme.sh jika belum ada
if [ ! -f "/root/.acme.sh/acme.sh" ]; then
    echo -e "[ ${green}INFO${NC} ] Installing acme.sh..."
    curl https://get.acme.sh | sh -s email=admin@gmail.com
    source ~/.bashrc
fi

/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

echo -e "[ ${green}INFO${NC} ] Renew cert done... "
sleep 1
echo $domain > /etc/xray/domain

# Restart service dengan aman
if [[ ! -z "$Cek" ]]; then
    systemctl restart $Cek 2>/dev/null
fi
systemctl restart xray
systemctl restart nginx

echo -e "[ ${green}INFO${NC} ] All finished... "
sleep 0.5
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
