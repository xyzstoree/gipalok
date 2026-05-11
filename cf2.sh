#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
Font="\033[0m"
gray="\e[1;30m"
total_ram=$(grep "MemTotal: " /proc/meminfo | awk '{ print $2}')
totalram=$(($total_ram / 1024))
# FIX: Added --max-time to prevent hanging
MYIP=$(curl -sS --max-time 5 ipv4.icanhazip.com 2>/dev/null || curl -sS --max-time 5 ifconfig.me 2>/dev/null || echo "-")
LAST_DOMAIN="$(cat /etc/xray/domain 2>/dev/null || echo '-')"
NS="$(cat /etc/xray/dns 2>/dev/null || echo '-')"
# FIX: red() was using GREEN color code \033[32m — corrected to RED \033[31m
red()   { echo -e "\\033[31;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
# FIX: vpnpro declared at script scope so ns_domain_cloudflare() can also access it
vpnpro=""
clear

function get_acme_domain() {
    vpnpro=$(cat /etc/xray/domain 2>/dev/null || echo "$LAST_DOMAIN")
    clear
    echo -e " ┌─────────────────────────────────────────────────────────┐"
    echo -e "─│                        ${CYAN}WELCOME TO${NC}                       │─"
    echo -e "─│    ${ORANGE}GIPALOK PREMIUM SCRIPT${NC}                               │─"
    echo -e " └─────────────────────────────────────────────────────────┘"
    echo -e "─────────────────────────────────────────────────────────────"
    echo -e "               ${GREEN}PROSES GANTI DOMAIN & NS-DOMAIN${NC}"
    echo -e "─────────────────────────────────────────────────────────────"
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Proses sedang berlangsung${NC} "
    systemctl stop nginx 2>/dev/null || true
    systemctl stop haproxy 2>/dev/null || true
    systemctl stop xray 2>/dev/null || true
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Memperbarui semua sertifikat${NC}"
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Sedang mendownload sertifikat kedalam VPS${NC}"
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade >/dev/null 2>&1
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1
    /root/.acme.sh/acme.sh --issue -d "$vpnpro" --standalone -k ec-256 >/dev/null 2>&1
    ~/.acme.sh/acme.sh --installcert -d "$vpnpro" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc >/dev/null 2>&1
    # FIX: tee now writes to /etc/haproxy/yha.pem (original had tee >/dev/null — file never created)
    rm -f /etc/haproxy/yha.pem
    cat /etc/xray/xray.crt /etc/xray/xray.key | tee /etc/haproxy/yha.pem >/dev/null 2>&1
    echo -e "   [${GREEN}DONE${NC}] ${CYAN}Pembaruan Sertifikat Selesai${NC}"
    sed -i "s/${LAST_DOMAIN}/${vpnpro}/g" /etc/nginx/conf.d/xray.conf >/dev/null 2>&1
    # FIX: duplicate sed on index.html removed (was called twice in original)
    sed -i "s/${LAST_DOMAIN}/${vpnpro}/g" /var/www/html/index.html >/dev/null 2>&1
    sed -i "s/${LAST_DOMAIN}/${vpnpro}/g" /etc/haproxy/haproxy.cfg >/dev/null 2>&1
    sed -i "s/${LAST_DOMAIN}/${vpnpro}/g" /etc/openvpn/tcp.ovpn >/dev/null 2>&1
    sed -i "s/${LAST_DOMAIN}/${vpnpro}/g" /etc/openvpn/udp.ovpn >/dev/null 2>&1
    sed -i "s/${LAST_DOMAIN}/${vpnpro}/g" /etc/openvpn/ssl.ovpn >/dev/null 2>&1
    sed -i "s/${LAST_DOMAIN}/${vpnpro}/g" /etc/openvpn/ws-ssl.ovpn >/dev/null 2>&1
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Restart Daemon Reload Service${NC}"
    systemctl daemon-reload >/dev/null 2>&1
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Restart SlowDns Server Service${NC}"
    systemctl restart server >/dev/null 2>&1 || true
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Restart SlowDns Client Service${NC}"
    systemctl restart client >/dev/null 2>&1 || true
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Restart Haproxy Loadbalance${NC}"
    systemctl restart haproxy >/dev/null 2>&1 || true
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Restart Nginx WebServer${NC}"
    systemctl restart nginx >/dev/null 2>&1 || true
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Restart Xray Service${NC}"
    systemctl restart xray >/dev/null 2>&1 || true
    sleep 2
    echo -e "   [${GREEN}DONE${NC}] ${CYAN}Ganti Domain dan Restart Service Selesai${NC}"
    sleep 2
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Proses pointing NS-Domain${NC} "
    sleep 3
}

ns_domain_cloudflare() {
    # FIX: wget now uses -q -O flag to save file properly
    wget -q https://raw.githubusercontent.com/xyzstoree/gipalok/main/ssh/cfnvpnpro.sh -O cfnvpnpro.sh \
        && chmod +x cfnvpnpro.sh && ./cfnvpnpro.sh >/dev/null 2>&1
    NSVPSKU=$(cat /etc/xray/dns 2>/dev/null || echo "$NS")
    sleep 3
    sed -i "s/$NS/$NSVPSKU/g" /etc/systemd/system/client.service >/dev/null 2>&1 || true
    sed -i "s/$NS/$NSVPSKU/g" /etc/systemd/system/server.service >/dev/null 2>&1 || true
    # FIX: $vpnpro now accessible because it's declared at script scope
    echo -e "   [${ORANGE}DONE${NC}] ${CYAN}Domain kamu sekarang${NC} [${ORANGE}${vpnpro}${NC}]"
    sleep 2
    echo -e "   [${ORANGE}DONE${NC}] ${CYAN}NS-Domain kamu sekarang${NC} [${ORANGE}${NSVPSKU}${NC}]"
    sleep 2
    echo -e "─────────────────────────────────────────────────────────────"
    read -n 2 -s -r -p "Tekan sembarang untuk kembali ke menu"
    menu
}

cloudflare() {
    echo -e "   [${ORANGE}INFO${NC}] ${CYAN}Proses Pointing Sedang Berlangsung${NC} "
    # FIX: wget uses -q -O flag to save file properly
    wget -q https://raw.githubusercontent.com/xyzstoree/gipalok/main/ssh/cfdvpnpro.sh -O cfdvpnpro.sh \
        && chmod +x cfdvpnpro.sh && ./cfdvpnpro.sh >/dev/null 2>&1
    get_acme_domain
    ns_domain_cloudflare
}

clear
echo -e " ┌─────────────────────────────────────────────────────────┐"
echo -e "─│                        ${CYAN}WELCOME TO${NC}                       │─"
echo -e "─│    ${ORANGE}GIPALOK PREMIUM SCRIPT${NC}                               │─"
echo -e " └─────────────────────────────────────────────────────────┘"
echo -e "─────────────────────────────────────────────────────────────
              ${CYAN}Hostname${NC}     :  ${ORANGE}$LAST_DOMAIN${NC}
              ${CYAN}Public IP${NC}    :  ${ORANGE}$MYIP${NC}
              ${CYAN}Total RAM${NC}    :  ${ORANGE}$totalram MB${NC}
─────────────────────────────────────────────────────────────"
echo -e "  ${CYAN}[1]${NC} ${RED}•${NC} Pointing domain ke Cloudflare"
echo -e "  ${CYAN}[0]${NC} ${RED}•${NC} Kembali Ke Menu"
echo -e "─────────────────────────────────────────────────────────────"
read -p "Silahkan masukkan pilihan anda [1/0] : " NUM_MENU

case $NUM_MENU in
1) cloudflare ;;
0) menu ;;
*) menu ;;
esac
