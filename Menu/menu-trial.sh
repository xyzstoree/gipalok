#!/bin/bash
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=$(date +"%Y-%m-%d" -d "$dateFromServer")

BIBlack='\033[1;90m'
BIRed='\033[1;91m'
BIGreen='\033[1;92m'
BIYellow='\033[1;93m'
BIBlue='\033[1;94m'
BIPurple='\033[1;95m'
BICyan='\033[1;96m'
BIWhite='\033[1;97m'
UWhite='\033[4;37m'
On_IPurple='\033[0;105m'
On_IRed='\033[0;101m'
IBlack='\033[0;90m'
IRed='\033[0;91m'
IGreen='\033[0;92m'
IYellow='\033[0;93m'
IBlue='\033[0;94m'
IPurple='\033[0;95m'
ICyan='\033[0;96m'
IWhite='\033[0;97m'
NC='\e[0m'
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export LIGHT='\033[0;37m'
export NC='\033[0m'

MYIP=$(wget -qO- ipinfo.io/ip);

clear
echo -e "${BICyan} ┌─────────────────────────────────────────────────────┐${NC}"
echo -e "       ${BIWhite}${UWhite}TRIALL ${NC}"
echo -e ""
echo -e "     ${BICyan}[${BIWhite}01${BICyan}] Trial Account SSH & OVPN   "
echo -e "     ${BICyan}[${BIWhite}02${BICyan}] Trial Account VMESS    "
echo -e "     ${BICyan}[${BIWhite}03${BICyan}] Trial Account VLESS     "
echo -e "     ${BICyan}[${BIWhite}04${BICyan}] Trial Account TROJAN   "
echo -e " ${BICyan}└─────────────────────────────────────────────────────┘${NC}"
echo -e "     ${BIYellow}Press x or [ Ctrl+C ] • To-${BIWhite}Exit${NC}"
echo ""
read -p " Select menu : " opt
echo -e ""
case $opt in
1) clear ; trial ;;
2) clear ; trialvmess ;;
3) clear ; trialvless ;;
4) clear ; trialtrojan ;;
0) clear ; menu ;;
x) menu-trial ;;
*) echo "Pilihan tidak valid" ; sleep 1 ; menu-trial ;;
esac
