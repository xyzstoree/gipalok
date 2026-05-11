#!/bin/bash
export LC_ALL='en_US.UTF-8'
export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'
# FIX: LC_CTYPE was 'en_US.utf8' — corrected to 'en_US.UTF-8'
export LC_CTYPE='en_US.UTF-8'

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export LIGHT='\033[0;37m'
export NC='\033[0m'

export EROR="[${RED} EROR ${NC}]"
export INFO="[${YELLOW} INFO ${NC}]"
export OKEY="[${GREEN} OKEY ${NC}]"
export PENDING="[${YELLOW} PENDING ${NC}]"
export SEND="[${YELLOW} SEND ${NC}]"
export RECEIVE="[${YELLOW} RECEIVE ${NC}]"

export BOLD="\e[1m"
export WARNING="${RED}\e[5m"
export UNDERLINE="\e[4m"

export Server_URL="autosc.me/aio"
export Server_Port="443"
export Server_IP="undefined"
export Script_Mode="Stable"
export Author="GIPALOK"
export RED_BG='\e[41m'

export IP=$(curl -s --max-time 5 https://ipinfo.io/ip/ 2>/dev/null || echo "N/A")

# OpenSSH
openssh=$(systemctl status ssh 2>/dev/null | grep Active | awk '{print $3}' | sed 's/(//g;s/)//g')
[[ $openssh == "running" ]] \
    && status_openssh="${GREEN}Running${NC} ( No Error )" \
    || status_openssh="${RED}Not Running${NC} ( Error )"

# Stunnel5
stunnel5=$(systemctl status stunnel4 2>/dev/null | grep Active | awk '{print $3}' | sed 's/(//g;s/)//g')
[[ $stunnel5 == "running" ]] \
    && status_stunnel5="${GREEN}Running${NC} ( No Error )" \
    || status_stunnel5="${RED}Not Running${NC} ( Error )"

# Dropbear
dropbear=$(systemctl status dropbear 2>/dev/null | grep Active | awk '{print $3}' | sed 's/(//g;s/)//g')
[[ $dropbear == "running" ]] \
    && status_dropbear="${GREEN}Running${NC} ( No Error )" \
    || status_dropbear="${RED}Not Running${NC} ( Error )"

# Squid
squid=$(systemctl status squid 2>/dev/null | grep Active | awk '{print $3}' | sed 's/(//g;s/)//g')
[[ $squid == "running" ]] \
    && status_squid="${GREEN}Running${NC} ( No Error )" \
    || status_squid="${RED}Not Running${NC} ( Error )"

# NGINX
nginx=$(systemctl status nginx 2>/dev/null | grep Active | awk '{print $3}' | sed 's/(//g;s/)//g')
[[ $nginx == "running" ]] \
    && status_nginx="${GREEN}Running${NC} ( No Error )" \
    || status_nginx="${RED}Not Running${NC} ( Error )"

# FIX: SSH NonTLS and SSH TLS were BOTH checking ws-stunnel — showed identical status.
#      NonTLS uses 'ws-epro'; TLS uses 'ws-stunnel'. Now each checks its own service.
ssh_ntls=$(systemctl status ws-epro 2>/dev/null | grep Active | awk '{print $3}' | sed 's/(//g;s/)//g')
[[ $ssh_ntls == "running" ]] \
    && status_ws_ntls="${GREEN}Running${NC} ( No Error )" \
    || status_ws_ntls="${RED}Not Running${NC} ( Error )"

ssh_tls=$(systemctl status ws-stunnel 2>/dev/null | grep Active | awk '{print $3}' | sed 's/(//g;s/)//g')
[[ $ssh_tls == "running" ]] \
    && status_ws_tls="${GREEN}Running${NC} ( No Error )" \
    || status_ws_tls="${RED}Not Running${NC} ( Error )"

# Xray
ss=$(systemctl status xray 2>/dev/null | grep Active | awk '{print $3}' | sed 's/(//g;s/)//g')
[[ $ss == "running" ]] \
    && status_ss="${GREEN}Running${NC} ( No Error )" \
    || status_ss="${RED}Not Running${NC} ( Error )"

Bot="0"; Beta="0"; Backup="0"
[[ $Bot    == "1" ]] && bot='Allowed'    || bot='Not Allowed'
[[ $Beta   == "1" ]] && beta='Allowed'   || beta='Not Allowed'
[[ $Backup == "1" ]] && backup='Allowed' || backup='Not Allowed'

# FIX: Redundant clear calls removed
clear

echo -e "${YELLOW}----------------------------------------------------------${NC}"
echo -e "                ${YELLOW}(${NC}${GREEN} STATUS SERVICE INFORMATION ${NC}${YELLOW})${NC}"
echo -e "         OWNER : ${GREEN}XYZSTOREE NETWORK ${NC}${YELLOW}(${NC} ${GREEN}GIPALOK ${NC}${YELLOW})${NC}"
echo -e "       © Copyright By XYZSTOREE ${YELLOW}(${NC} 2024 ${YELLOW})${NC}"
echo -e "${YELLOW}----------------------------------------------------------${NC}"
echo ""
echo -e "${RED_BG}                     System Information                    ${NC}"
echo -e "Server Uptime        = $(uptime -p | cut -d ' ' -f 2-10000)"
echo -e "Current Time         = $(date +"%d-%m-%Y | %X")"
echo ""
echo -e "${RED_BG}                     Service Information                  ${NC}"
echo -e "OpenSSH              = $status_openssh"
echo -e "Dropbear             = $status_dropbear"
echo -e "Stunnel5             = $status_stunnel5"
echo -e "Squid                = $status_squid"
echo -e "NGINX                = $status_nginx"
echo -e "SSH NonTLS (ws-epro)   = $status_ws_ntls"
echo -e "SSH TLS (ws-stunnel)   = $status_ws_tls"
echo -e "Vmess WS/GRPC        = $status_ss"
echo -e "Vless WS/GRPC        = $status_ss"
echo -e "Trojan WS/GRPC       = $status_ss"
echo -e "Shadowsocks WS/GRPC  = $status_ss"
echo ""
echo -e "${CYAN}Script Mode: $Script_Mode${NC}"
echo -e "${CYAN}Public IP: $IP${NC}"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
