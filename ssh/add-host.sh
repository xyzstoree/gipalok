#!/bin/bash
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`

# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

# Pastikan folder dan file yang diperlukan ada
mkdir -p /var/lib/Anggun
touch /root/log-install.txt

#########################
cekray=`cat /root/log-install.txt | grep -ow "XRAY" | sort | uniq`

# // Starting Setup Domain
echo -e "${YELLOW}-----------------------------------------------------${NC}"
echo -e "1. Menggunakan Domain Pribadi ?"
echo -e "2. Menggunakan Domain Otomatis ?"
echo -e "${YELLOW}-----------------------------------------------------${NC}"
echo ""
read -p "$( echo -e "${GREEN}Input Your Choose ? ${NC}(${YELLOW}1/2${NC})${NC} " )" choose_domain

if [[ $choose_domain == "2" ]]; then # // Using Automatic Domain

# // String / Request Data
DOMAIN=anggunre.shop
sub=$(</dev/urandom tr -dc a-z0-9 | head -c5)
dns=${sub}.anggunre.shop
CF_ID=arismar.amar@gmail.com
CF_KEY=88ecae78b53455a919ccecd22bdbd0332f7c7
set -euo pipefail
IP=$(wget -qO- icanhazip.com);
echo "Updating DNS for ${dns}..."
ZONE=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" | jq -r .result[0].id)

RECORD=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${dns}" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" | jq -r .result[0].id)

if [[ "${#RECORD}" -le 10 ]]; then
     RECORD=$(curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'${dns}'","content":"'${IP}'","ttl":120,"proxied":false}' | jq -r .result.id)
fi

RESULT=$(curl -sLX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD}" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'${dns}'","content":"'${IP}'","ttl":120,"proxied":false}')
echo "NS : $dns"
echo $dns > /root/domain
echo $dns > /root/nsdomain
sleep 1
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
yellow "Domain added.."
sleep 3
domain=$(cat /root/domain)
nsdomain=$(cat /root/nsdomain)
cp -r /root/domain /etc/xray/domain

# // Making Certificate
clear
sleep 2
systemctl stop nginx
systemctl stop xray
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
menu
else
read -rp "Domain/Host: " -e host
if [ -z "$host" ]; then
    echo "Domain tidak boleh kosong!"
    read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
    menu
else
    mkdir -p /var/lib/Anggun
    echo "IP=$host" > /var/lib/Anggun/ipvps.conf
    echo $host > /etc/xray/domain
    echo "Dont forget to renew cert"
    echo ""
    read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
    certv2ray
fi
fi
