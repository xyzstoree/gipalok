#!/bin/bash

mkdir -p /var/lib/Anggun /etc/Anggun/Queue/ssh/ip
touch /root/log-install.txt

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'

clear
source /var/lib/Anggun/ipvps.conf 2>/dev/null || true
if [[ -z "${IP:-}" ]]; then
    domain=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || echo "-")
else
    domain=$IP
fi
trgo="$(grep -w "Trojan Go" ~/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"
[ -z "$trgo" ] && trgo="443"

until [[ ${user:-} =~ ^[a-zA-Z0-9_]+$ && ${user_EXISTS:-1} == '0' ]]; do
    read -rp "User : " -e user
    if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "Username hanya boleh huruf, angka, underscore."
        continue
    fi
    user_EXISTS=$(grep -w "^### $user " /etc/trojan-go/akun.conf 2>/dev/null | wc -l)
    if [[ ${user_EXISTS} != '0' ]]; then
        echo ""
        echo -e "Username ${RED}${user}${NC} sudah ada, pilih nama lain."
        user_EXISTS=1; user=""
    fi
done

uuid=$(cat /proc/sys/kernel/random/uuid)
read -p "Expired (Days) : " masaaktif
[ -z "$masaaktif" ] && masaaktif=30
if ! echo "$masaaktif" | grep -Eq '^[0-9]+$'; then masaaktif=30; fi

# FIX: date -d "+$masaaktif days" (original was missing + prefix → wrong expiry)
exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")
hariini=$(date +"%Y-%m-%d")

# FIX: Original used broken sed pattern to inject raw string into JSON.
#      Now uses jq for proper JSON manipulation of trojan-go config.
if [ -f /etc/trojan-go/config.json ]; then
    tmp=$(mktemp)
    jq --arg pass "$uuid" '.password += [$pass]' /etc/trojan-go/config.json > "$tmp" \
        && mv "$tmp" /etc/trojan-go/config.json
fi
echo -e "### $user $exp" >> /etc/trojan-go/akun.conf
systemctl restart trojan-go.service 2>/dev/null || true

link="trojan-go://${uuid}@${domain}:${trgo}/?sni=${domain}&type=ws&host=${domain}&path=%2Ftrojango#${user}"
link1="trojan://${uuid}@${domain}:${trgo}/?sni=${domain}&type=ws&host=${domain}&path=%2Ftrojango#${user}"

clear
{
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "\E[0;41;36m      TROJAN GO      \E[0m"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Remarks    : ${user}"
echo -e "IP/Host    : ${domain}"
echo -e "Address    : ${domain}"
echo -e "Port       : ${trgo}"
echo -e "Key        : ${uuid}"
echo -e "Encryption : none"
echo -e "Path       : /trojango"
echo -e "Created    : $hariini"
echo -e "Expired    : $exp"
echo -e "========================="
echo -e "Link TrGo         : ${link}"
echo -e "Link TrGo (v2ray) : ${link1}"
echo -e "========================="
echo -e "Script Anggun Premium"
echo ""
} | tee -a /etc/log-create-user.log
read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
menu
