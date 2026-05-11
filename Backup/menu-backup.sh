#!/bin/bash
# Tampilan menu diubah saja; alur/perintah tetap sama.

clear

# Warna
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Lebar garis
LINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

printf "${CYAN}%s${NC}\n" "$LINE"
printf "${WHITE}              MENU BACKUP PANEL${NC}\n"
printf "${CYAN}%s${NC}\n" "$LINE"
printf "${YELLOW}        Backup, Restore & Auto Backup${NC}\n"
printf "${CYAN}%s${NC}\n\n" "$LINE"

printf "${WHITE}  [${GREEN}1${WHITE}]${NC} Input API Bot & Chat ID\n"
printf "${WHITE}  [${GREEN}2${WHITE}]${NC} Backup Manual\n"
printf "${WHITE}  [${GREEN}3${WHITE}]${NC} Restore Backup\n"
printf "${WHITE}  [${GREEN}4${WHITE}]${NC} Auto Backup\n"
printf "${WHITE}  [${RED}5${WHITE}]${NC} Back To Main Menu\n\n"

printf "${CYAN}%s${NC}\n" "$LINE"
printf "${YELLOW}Pilih menu sesuai nomor.${NC}\n"
printf "${CYAN}%s${NC}\n\n" "$LINE"

read -rp "Pilih Nomor └╼>>> " opt

case $opt in
    1)
        clear
        set-telegram
        ;;
    2)
        clear
        backup
        ;;
    3)
        clear
        restore
        ;;
    4)
        clear
        autobackup
        ;;
    5)
        clear
        menu
        ;;
    *)
        clear
        menu-backup
        ;;
esac
