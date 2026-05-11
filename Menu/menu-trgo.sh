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
IBlue='\033[0;94d'
IPurple='\033[0;95m'
ICyan='\033[0;96m'
IWhite='\033[0;97m'
NC='\e[0m'
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

MYIP=$(wget -qO- ipinfo.io/ip);

clear
echo -e "${BICyan} ┌─────────────────────────────────────────────────────┐${NC}"
echo -e "       ${BIWhite}${UWhite}TROJAN GO ${NC}"
echo -e ""
echo -e "     ${BICyan}1. ${BIYellow}Create Account Trojan Go    "
echo -e "     ${BICyan}2. ${BIYellow}Trial Account Trojan Go     "
echo -e "     ${BICyan}3. ${BIYellow}Renew Account Trojan Go Active Life      "
echo -e "     ${BICyan}4. ${BIYellow}Delete Account Trojan Go     "
echo -e "     ${BICyan}5. ${BIYellow}Check User Login Trojan Go     "
echo -e " ${BICyan}└─────────────────────────────────────────────────────┘${NC}"
echo -e "     ${BIYellow}Press x or [ Ctrl+C ] • To-${BIWhite}Exit${NC}"
echo -e ""
read -p " Select menu : " opt
echo -e ""
case $opt in
1) clear ; addtrgo ;;
2) clear ; trialtrojango ;;
3) clear ; renewtrgo ;;
4) clear ; deltrgo ;;
5) clear ; cektrgo ;;
0) clear ; menu ;;
x) menu-trgo ;;
*) echo "Pilihan tidak valid" ; sleep 1 ; menu-trgo ;;
esac
