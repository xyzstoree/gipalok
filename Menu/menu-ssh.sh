#!/bin/bash
Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
GREENBG="\033[42;37m"
REDBG="\033[41;37m"
OK="${Green}--->${FONT}"
ERROR="${RED}[ERROR]${FONT}"
GRAY="\e[1;30m"
NC='\e[0m'
red='\e[1;31m'
green='\e[0;32m'
DF='\e[39m'
Bold='\e[1m'
Blink='\e[5m'
yell='\e[33m'
red='\e[31m'
green='\e[32m'
blue='\e[34m'
PURPLE='\e[35m'
cyan='\e[36m'
Lred='\e[91m'
Lgreen='\e[92m'
Lyellow='\e[93m'
NC='\e[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
LIGHT='\033[0;37m'
grenbo="\e[92;1m"
red() { echo -e "\\033[32;1m${*}\\033[0m"; }

MYIP=$(wget -qO- ipinfo.io/ip);

clear
echo -e "\033[1;93m┌──────────────────────────────────────────┐\033[0m"
echo -e "                SSH & OpenVPN           "
echo -e "\033[1;93m└──────────────────────────────────────────┘\033[0m"
echo -e "\033[1;93m┌──────────────────────────────────────────┐\033[0m"
echo -e "  ${ORANGE}[1].${NC}\033[0;36m Create SSH & OpenVPN Account${NC}"
echo -e "  ${ORANGE}[2].${NC}\033[0;36m Trial SSH & OpenVPN ${NC}"
echo -e "  ${ORANGE}[3].${NC}\033[0;36m Renew SSH & OpenVPN ${NC}"
echo -e "  ${ORANGE}[4].${NC}\033[0;36m Check User Login SSH & OpenVPN${NC}"
echo -e "  ${ORANGE}[5].${NC}\033[0;36m Daftar Member SSH & OpenVPN ${NC}"
echo -e "  ${ORANGE}[6].${NC}\033[0;36m Hapus SSH & OpenVpn Account ${NC}"
echo -e "  ${ORANGE}[7].${NC}\033[0;36m Hapus User Expired SSH & OpenVPN ${NC}"
echo -e "  ${ORANGE}[8].${NC}\033[0;36m Set up Autokill SSH ${NC}"
echo -e "  ${ORANGE}[9].${NC}\033[0;36m Cek User Multi Login SSH ${NC}"
echo -e " ${ORANGE}[10].${NC}\033[0;36m Lock Account User ${NC}"
echo -e " ${ORANGE}[11].${NC}\033[0;36m Unlock Account User ${NC}"
echo -e " ${ORANGE}[12].${NC}\033[0;36m Exit ${NC}"
echo -e "\033[1;93m└──────────────────────────────────────────┘\033[0m"
echo -e ""
read -p " Select Menu [1-12] :  "  opt
echo -e ""
case $opt in
1) clear ; usernew ; menu-ssh ;;
2) clear ; trial ; menu-ssh ;;
3) clear ; renew ; menu-ssh ;;
4) clear ; cek ; menu-ssh ;;
5) clear ; member ; menu-ssh ;;
6) clear ; hapus ; menu-ssh ;;
7) clear ; delete ; menu-ssh ;;
8) clear ; autokill ; menu-ssh ;;
9) clear ; ceklim ; menu-ssh ;;
10) clear ; user-lock ; menu-ssh ;;
11) clear ; user-unlock ; menu-ssh ;;
0) clear ; menu ; menu-ssh ;;
x) menu-ssh ;;
*) echo "Pilihan tidak valid" ; sleep 1 ; menu ;;
esac
