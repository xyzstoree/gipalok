#!/bin/bash
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

MYIP=$(wget -qO- ipinfo.io/ip);

clear
echo -e "${BICyan} ┌─────────────────────────────────────────────────────┐${NC}"
echo -e "       ${BIWhite}${UWhite}VMESS MENU ${NC}"
echo -e ""
echo -e "     ${BICyan}1. ${BIYellow}Create Account XRAY Vmess Websocket "
echo -e "     ${BICyan}2. ${BIYellow}Trial Account XRAY Vmess     "
echo -e "     ${BICyan}3. ${BIYellow}Renew Account XRAY Vmess Active "
echo -e "     ${BICyan}4. ${BIYellow}Delete Account XRAY Vmess Websocket  "
echo -e "     ${BICyan}5. ${BIYellow}Check User Login XRAY Vmess     "
echo -e " ${BICyan}└─────────────────────────────────────────────────────┘${NC}"
echo -e ""
read -p " Select menu :  "  opt
echo -e ""
case $opt in
1) clear ; add-ws ; menu-vmess ;;
2) clear ; trialvmess ; menu-vmess ;;
3) clear ; renew-ws ; menu-vmess ;;
4) clear ; del-ws ; menu-vmess ;;
5) clear ; cek-ws ; menu-vmess ;;
0) clear ; menu ; menu-vmess ;;
x) menu-vmess ;;
*) echo "Pilihan tidak valid" ; sleep 1 ; menu-vmess ;;
esac
