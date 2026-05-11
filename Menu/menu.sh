#!/bin/bash

clear

# =========================
# COLOR
# =========================
NC='\033[0m'
z="\033[96m"
r="\033[1;31m"
y='\033[1;33m'
green='\033[0;32m'
IWhite='\033[0;97m'
CYAN="\033[96m"

KANAN="\033[1;32m<\033[1;33m<\033[1;31m<${NC}"
KIRI="\033[1;32m>\033[1;33m>\033[1;31m>${NC}"
a=" ${CYAN}SCRIPT PREMIUM GIPALOK"

# =========================
# ACCOUNT COUNT
# =========================
vma=$(jq '._metadata.vmess // {} | length' /etc/xray/config.json 2>/dev/null)
vla=$(jq '._metadata.vless // {} | length' /etc/xray/config.json 2>/dev/null)
tra=$(jq '._metadata.trojan // {} | length' /etc/xray/config.json 2>/dev/null)
ssa=$(jq '._metadata.shadowsocks // {} | length' /etc/xray/config.json 2>/dev/null)

[ -z "$vma" ] && vma=0
[ -z "$vla" ] && vla=0
[ -z "$tra" ] && tra=0
[ -z "$ssa" ] && ssa=0

ssh1="$(awk -F: '$3 >= 1000 && $1 != "nobody" && $7 != "/usr/sbin/nologin" && $7 != "/bin/false" {print $1}' /etc/passwd | wc -l)"

# =========================
# BASIC INFO
# =========================
domain=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || echo "-")
uptime="$(uptime -p | cut -d " " -f 2-10)"
MODEL=$(grep -w PRETTY_NAME /etc/os-release | head -n1 | sed 's/PRETTY_NAME=//g' | sed 's/"//g')
ISP=$(curl -s --max-time 2 ipinfo.io/org | cut -d " " -f 2-10)
CITY=$(curl -s --max-time 2 ipinfo.io/city)
IPVPS=$(curl -s --max-time 2 ipinfo.io/ip)

[ -z "$ISP" ] && ISP="-"
[ -z "$CITY" ] && CITY="-"
[ -z "$IPVPS" ] && IPVPS="-"

tram=$(free -m | awk 'NR==2 {print $2}')
uram=$(free -m | awk 'NR==2 {print $3}')

# =========================
# SCRIPT ACTIVE PERIOD
# =========================
EXP_FILE="/etc/Anggun/script-expired"

if [ ! -f "$EXP_FILE" ]; then
    mkdir -p /etc/Anggun
    date -d "365 days" +"%Y-%m-%d" > "$EXP_FILE"
fi

SCRIPT_EXP=$(cat "$EXP_FILE" 2>/dev/null)
TODAY_SEC=$(date +%s)
EXP_SEC=$(date -d "$SCRIPT_EXP" +%s 2>/dev/null || echo 0)

if [ "$EXP_SEC" -gt "$TODAY_SEC" ]; then
    SISA_HARI=$(( (EXP_SEC - TODAY_SEC) / 86400 ))
    SCRIPT_ACTIVE="${SISA_HARI} hari"
else
    SCRIPT_ACTIVE="Expired"
fi

# =========================
# VNSTAT TRAFFIC AUTO INTERFACE
# =========================
NETIF=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
[ -z "$NETIF" ] && NETIF=$(ip -o -4 route show to default | awk '{print $5; exit}')
[ -z "$NETIF" ] && NETIF="eth0"

if command -v vnstat >/dev/null 2>&1; then
    VNLINE=$(vnstat -i "$NETIF" --oneline 2>/dev/null)
    ttoday=$(echo "$VNLINE" | awk -F';' '{print $6}')
    tyest=$(echo "$VNLINE" | awk -F';' '{print $9}')
    tmon=$(echo "$VNLINE" | awk -F';' '{print $11}')
else
    ttoday=""
    tyest=""
    tmon=""
fi

[ -z "$ttoday" ] && ttoday="0 B"
[ -z "$tyest" ] && tyest="0 B"
[ -z "$tmon" ] && tmon="0 B"

# =========================
# SERVICE STATUS
# =========================
service_status() {
    local svc="$1"
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "${green}ON${NC}"
    else
        echo -e "${r}OFF${NC}"
    fi
}

ressh=$(service_status ssh)
resngx=$(service_status nginx)
resv2r=$(service_status xray)
resst=$(service_status stunnel4)
resdbr=$(service_status dropbear)

if systemctl is-active --quiet ws 2>/dev/null; then
    ressshws="${green}ON${NC}"
elif systemctl is-active --quiet ws-stunnel 2>/dev/null; then
    ressshws="${green}ON${NC}"
else
    ressshws="${r}OFF${NC}"
fi

# =========================
# FUNCTIONS
# =========================
addhost() {
    clear
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
    read -rp "Domain/Host: " -e host
    echo ""

    if [ -z "$host" ]; then
        echo "Domain tidak boleh kosong!"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        read -n 1 -s -r -p "Press any key to back on menu"
        menu
    else
        echo "IP=$host" > /var/lib/Anggun/ipvps.conf
        echo "$host" > /etc/xray/domain
        echo "$host" > /root/domain
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo "Domain berhasil diganti."
        echo "Jangan lupa renew cert jika perlu."
        echo ""
        read -n 1 -s -r -p "Press any key to back on menu"
        menu
    fi
}

change_banner() {
    clear
    nano /etc/kyt.txt
    systemctl restart ssh 2>/dev/null || true
    systemctl restart dropbear 2>/dev/null || true
    menu
}

set_expired_script() {
    clear
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;41;36m        SET SCRIPT EXPIRED         \E[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
    echo "Expired sekarang : $SCRIPT_EXP"
    echo "Sisa aktif       : $SCRIPT_ACTIVE"
    echo ""
    echo "Contoh input:"
    echo "  2026-12-31"
    echo "  2099-12-31 untuk lifetime"
    echo ""
    read -rp "Masukkan tanggal expired baru: " newexp

    if date -d "$newexp" +"%Y-%m-%d" >/dev/null 2>&1; then
        mkdir -p /etc/Anggun
        date -d "$newexp" +"%Y-%m-%d" > "$EXP_FILE"
        echo ""
        echo "Expired script berhasil diubah ke: $(cat "$EXP_FILE")"
    else
        echo ""
        echo "Format tanggal salah."
    fi

    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    menu
}

# =========================
# DISPLAY MENU
# =========================
clear
figlet 'GIPALOK' | lolcat 2>/dev/null || echo "GIPALOK"

line="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
short="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "${CYAN}╭${line}╮${NC}"
echo -e "${CYAN}│${NC} ${IWhite}              ⇱  MAIN MENU GIPALOK  ⇲              ${CYAN}│${NC}"
echo -e "${CYAN}├${line}┤${NC}"
printf "${CYAN}│${NC} ${y}OS        ${NC}: %-40s ${CYAN}│${NC}\n" "$MODEL"
printf "${CYAN}│${NC} ${y}ISP       ${NC}: %-40s ${CYAN}│${NC}\n" "$ISP"
printf "${CYAN}│${NC} ${y}CITY      ${NC}: %-40s ${CYAN}│${NC}\n" "$CITY"
printf "${CYAN}│${NC} ${y}IP VPS    ${NC}: %-40s ${CYAN}│${NC}\n" "$IPVPS"
printf "${CYAN}│${NC} ${y}DOMAIN    ${NC}: %-40s ${CYAN}│${NC}\n" "$domain"
printf "${CYAN}│${NC} ${y}UPTIME    ${NC}: %-40s ${CYAN}│${NC}\n" "$uptime"
printf "${CYAN}│${NC} ${y}RAM       ${NC}: %-40s ${CYAN}│${NC}\n" "$uram MB / $tram MB"
echo -e "${CYAN}╰${line}╯${NC}"

echo -e "${CYAN}╭${short}╮${NC}"
echo -e "${CYAN}│${NC} ${IWhite}ACCOUNT      SSH    VMESS    VLESS    TROJAN ${CYAN}│${NC}"
printf "${CYAN}│${NC} ${y}TOTAL     ${NC} %5s %8s %8s %9s ${CYAN}│${NC}\n" "$ssh1" "$vma" "$vla" "$tra"
echo -e "${CYAN}╰${short}╯${NC}"

echo -e "${CYAN}╭${line}╮${NC}"
echo -e "${CYAN}│${NC} ${IWhite}SERVICE STATUS${NC}                                      ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} SSH      : $ressh     NGINX   : $resngx     XRAY    : $resv2r ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} STUNNEL  : $resst     DROPBEAR: $resdbr     SSH-WS  : $ressshws ${CYAN}│${NC}"
echo -e "${CYAN}╰${line}╯${NC}"

echo -e "${CYAN}╭${line}╮${NC}"
echo -e "${CYAN}│${NC} ${IWhite}MENU OPTIONS${NC}                                        ${CYAN}│${NC}"
echo -e "${CYAN}├${line}┤${NC}"
echo -e "${CYAN}│${NC} [${r}01${NC}] SSH MENU          [${r}08${NC}] CHANGE BANNER        ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} [${r}02${NC}] VMESS MENU        [${r}09${NC}] BACKUP & RESTORE     ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} [${r}03${NC}] VLESS MENU        [${r}10${NC}] INSTALL UDP          ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} [${r}04${NC}] TROJAN MENU       [${r}11${NC}] ADD DOMAIN           ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} [${r}05${NC}] SETTING MENU      [${r}12${NC}] SET EXPIRED          ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} [${r}06${NC}] UPDATE SCRIPT     [${r}13${NC}] KELUAR SCRIPT        ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} [${r}07${NC}] STATUS RUNNING    [${r}14${NC}] SETUP BOT            ${CYAN}│${NC}"
echo -e "${CYAN}╰${line}╯${NC}"

echo -e "${CYAN}╭${line}╮${NC}"
printf "${CYAN}│${NC} ${IWhite}TRAFFIC TODAY ${NC}: ${r}%-34s${NC} ${CYAN}│${NC}\n" "$ttoday"
printf "${CYAN}│${NC} ${IWhite}YESTERDAY     ${NC}: ${r}%-34s${NC} ${CYAN}│${NC}\n" "$tyest"
printf "${CYAN}│${NC} ${IWhite}THIS MONTH    ${NC}: ${r}%-34s${NC} ${CYAN}│${NC}\n" "$tmon"
echo -e "${CYAN}╰${line}╯${NC}"

echo -e "${CYAN}╭${short}╮${NC}"
echo -e "${CYAN}│${NC} ${y}Version${NC} : 3.0 Lts                         ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} ${y}User   ${NC} : GIPALOK                         ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} ${y}Expired${NC} : $SCRIPT_ACTIVE                         ${CYAN}│${NC}"
echo -e "${CYAN}╰${short}╯${NC}"

echo -e " ${KIRI}${a} ${KANAN}"
echo -e "${IWhite}"
read -p " Select From Options [ 1 - 14 ] >> " opt

case $opt in
    1) clear ; menu-ssh ;;
    2) clear ; menu-vmess ;;
    3) clear ; menu-vless ;;
    4) clear ; menu-trojan ;;
    5) clear ; menu-set ;;
    6)
        clear
        updatemenu
        echo ""
        read -n 1 -s -r -p "Press any key to back on menu"
        menu
        ;;
    7) clear ; running ;;
    8) clear ; change_banner ;;
    9) clear ; menu-backup ;;
    10)
        clear
        UDPX="https://docs.google.com/uc?export=download&id=1S3IE25v_fyUfCLslnujFBSBMNunDHDk2"
        wget -O install-udp "$UDPX"
        chmod +x install-udp
        ./install-udp
        ;;
    11) clear ; addhost ;;
    12) clear ; set_expired_script ;;
    13) clear ; exit ;;
    14) clear ; menu-bot ;;
    *) clear ; menu ;;
esac
