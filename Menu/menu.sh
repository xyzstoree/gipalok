#!/bin/bash
# ============================================================================
# v7fix — main menu
# ============================================================================

# Load library
if [ -f /etc/v7fix/lib/common.sh ]; then
    # shellcheck disable=SC1091
    source /etc/v7fix/lib/common.sh
fi
if [ -f /etc/v7fix/lib/license.sh ]; then
    # shellcheck disable=SC1091
    source /etc/v7fix/lib/license.sh
fi

# License gate — always called, blocks menu when access denied.
# This is the bug fix: source of truth is the repo izin, not /etc/Anggun/script-expired.
if command -v v7_license_check >/dev/null 2>&1; then
    v7_license_check
fi

clear

# ----------------------------------------------------------------------------
# Colors (legacy — keep so menu UX matches the previous script 1:1)
# ----------------------------------------------------------------------------
NC='\033[0m'
z="\033[96m"
r="\033[1;31m"
y='\033[1;33m'
green='\033[0;32m'
IWhite='\033[0;97m'
CYAN="\033[96m"

KANAN="\033[1;32m<\033[1;33m<\033[1;31m<${NC}"
KIRI="\033[1;32m>\033[1;33m>\033[1;31m>${NC}"
a=" ${CYAN}SCRIPT PREMIUM V7FIX"

# ----------------------------------------------------------------------------
# Account count
# ----------------------------------------------------------------------------
vma=$(jq '._metadata.vmess // {} | length' /etc/xray/config.json 2>/dev/null)
vla=$(jq '._metadata.vless // {} | length' /etc/xray/config.json 2>/dev/null)
tra=$(jq '._metadata.trojan // {} | length' /etc/xray/config.json 2>/dev/null)
ssa=$(jq '._metadata.shadowsocks // {} | length' /etc/xray/config.json 2>/dev/null)

[ -z "$vma" ] && vma=0
[ -z "$vla" ] && vla=0
[ -z "$tra" ] && tra=0
[ -z "$ssa" ] && ssa=0

ssh1="$(awk -F: '$3 >= 1000 && $1 != "nobody" && $7 != "/usr/sbin/nologin" && $7 != "/bin/false" {print $1}' /etc/passwd | wc -l)"

# ----------------------------------------------------------------------------
# Basic info — uses cached helpers from lib/common.sh
# ----------------------------------------------------------------------------
domain=$(v7_get_domain 2>/dev/null || cat /etc/xray/domain 2>/dev/null || echo "-")
uptime_str="$(uptime -p | cut -d ' ' -f 2-10)"
MODEL=$(grep -w PRETTY_NAME /etc/os-release | head -n1 | sed 's/PRETTY_NAME=//g; s/"//g')
IPVPS=$(v7_get_ip 2>/dev/null || echo "-")

GEO="$(v7_get_geo 2>/dev/null)"
ISP="${GEO%%|*}"; CITY="${GEO##*|}"
[ -z "$ISP" ]  && ISP="-"
[ -z "$CITY" ] && CITY="-"

tram=$(free -m | awk 'NR==2 {print $2}')
uram=$(free -m | awk 'NR==2 {print $3}')

# ----------------------------------------------------------------------------
# Script expired display — sourced from license_check globals (repo izin),
# NOT from /etc/Anggun/script-expired any more.
# ----------------------------------------------------------------------------
SCRIPT_EXP="${LICENSE_EXP:-?}"
if [ -n "${LICENSE_DAYS_LEFT:-}" ] && [ "$LICENSE_DAYS_LEFT" -ge 0 ] 2>/dev/null; then
    SCRIPT_ACTIVE="${LICENSE_DAYS_LEFT} hari"
else
    SCRIPT_ACTIVE="Expired"
fi
LICENSE_OWNER="${LICENSE_USER:-?}"

# ----------------------------------------------------------------------------
# Vnstat traffic
# ----------------------------------------------------------------------------
NETIF=$(v7_get_nic 2>/dev/null || echo "eth0")

if command -v vnstat >/dev/null 2>&1; then
    VNLINE=$(vnstat -i "$NETIF" --oneline 2>/dev/null)
    ttoday=$(echo "$VNLINE" | awk -F';' '{print $6}')
    tyest=$(echo "$VNLINE"  | awk -F';' '{print $9}')
    tmon=$(echo "$VNLINE"   | awk -F';' '{print $11}')
fi

[ -z "$ttoday" ] && ttoday="0 B"
[ -z "$tyest" ]  && tyest="0 B"
[ -z "$tmon" ]   && tmon="0 B"

# ----------------------------------------------------------------------------
# Service status
# ----------------------------------------------------------------------------
service_status() {
    if systemctl is-active --quiet "$1" 2>/dev/null; then
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

# FIX: SSH-WS used to return both states from same probe — now properly OR's
if systemctl is-active --quiet ws 2>/dev/null \
   || systemctl is-active --quiet ws-stunnel 2>/dev/null \
   || systemctl is-active --quiet ws-epro 2>/dev/null; then
    ressshws="${green}ON${NC}"
else
    ressshws="${r}OFF${NC}"
fi

# ----------------------------------------------------------------------------
# Menu actions
# ----------------------------------------------------------------------------
addhost() {
    clear
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
    read -rp "Domain/Host: " -e host
    echo ""

    if [ -z "$host" ]; then
        echo "Domain tidak boleh kosong!"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
        menu
        return
    fi

    mkdir -p /var/lib/Anggun /etc/xray
    echo "IP=$host" > /var/lib/Anggun/ipvps.conf
    echo "$host"   > /etc/xray/domain
    # Symlink legacy path so old scripts that read /root/domain still work,
    # but the source of truth is /etc/xray/domain.
    ln -sf /etc/xray/domain /root/domain 2>/dev/null || cp /etc/xray/domain /root/domain
    # Invalidate cached IP since domain often differs from public IP
    rm -f /var/cache/v7fix/ip 2>/dev/null || true

    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo "Domain berhasil diganti."
    echo "Jangan lupa renew certificate jika perlu."
    echo ""
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
    menu
}

change_banner() {
    clear
    [ -f /etc/kyt.txt ] || touch /etc/kyt.txt
    nano /etc/kyt.txt
    systemctl restart ssh 2>/dev/null      || true
    systemctl restart dropbear 2>/dev/null || true
    menu
}

show_license_info() {
    clear
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;41;36m       INFO LISENSI SCRIPT          \E[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
    echo "IP VPS    : $IPVPS"
    echo "Owner     : $LICENSE_OWNER"
    echo "Expired   : $SCRIPT_EXP"
    echo "Sisa      : $SCRIPT_ACTIVE"
    echo "Status    : ${LICENSE_STATUS:-unknown}"
    echo ""
    echo "Source of truth:"
    echo "  https://github.com/xyzstoree/izin (file: ip)"
    echo ""
    echo "Catatan:"
    echo "  Untuk perpanjang/extend, admin update tanggal di repo izin."
    echo "  VPS otomatis ikut update tanpa perlu reinstall."
    echo ""
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
    menu
}

# ----------------------------------------------------------------------------
# Display menu
# ----------------------------------------------------------------------------
clear
figlet 'V7FIX' 2>/dev/null | lolcat 2>/dev/null || figlet 'V7FIX' 2>/dev/null || echo "V7FIX"

line="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
short="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "${CYAN}╭${line}╮${NC}"
echo -e "${CYAN}│${NC} ${IWhite}              ⇱  MAIN MENU V7FIX  ⇲                 ${CYAN}│${NC}"
echo -e "${CYAN}├${line}┤${NC}"
printf  "${CYAN}│${NC} ${y}OS        ${NC}: %-40s ${CYAN}│${NC}\n" "$MODEL"
printf  "${CYAN}│${NC} ${y}ISP       ${NC}: %-40s ${CYAN}│${NC}\n" "$ISP"
printf  "${CYAN}│${NC} ${y}CITY      ${NC}: %-40s ${CYAN}│${NC}\n" "$CITY"
printf  "${CYAN}│${NC} ${y}IP VPS    ${NC}: %-40s ${CYAN}│${NC}\n" "$IPVPS"
printf  "${CYAN}│${NC} ${y}DOMAIN    ${NC}: %-40s ${CYAN}│${NC}\n" "$domain"
printf  "${CYAN}│${NC} ${y}UPTIME    ${NC}: %-40s ${CYAN}│${NC}\n" "$uptime_str"
printf  "${CYAN}│${NC} ${y}RAM       ${NC}: %-40s ${CYAN}│${NC}\n" "$uram MB / $tram MB"
echo -e "${CYAN}╰${line}╯${NC}"

echo -e "${CYAN}╭${short}╮${NC}"
echo -e "${CYAN}│${NC} ${IWhite}ACCOUNT      SSH    VMESS    VLESS    TROJAN ${CYAN}│${NC}"
printf  "${CYAN}│${NC} ${y}TOTAL     ${NC} %5s %8s %8s %9s ${CYAN}│${NC}\n" "$ssh1" "$vma" "$vla" "$tra"
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
echo -e "${CYAN}│${NC} [${r}05${NC}] SETTING MENU      [${r}12${NC}] INFO LISENSI         ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} [${r}06${NC}] UPDATE SCRIPT     [${r}13${NC}] KELUAR SCRIPT        ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} [${r}07${NC}] STATUS RUNNING    [${r}14${NC}] SETUP BOT            ${CYAN}│${NC}"
echo -e "${CYAN}╰${line}╯${NC}"

echo -e "${CYAN}╭${line}╮${NC}"
printf  "${CYAN}│${NC} ${IWhite}TRAFFIC TODAY ${NC}: ${r}%-34s${NC} ${CYAN}│${NC}\n" "$ttoday"
printf  "${CYAN}│${NC} ${IWhite}YESTERDAY     ${NC}: ${r}%-34s${NC} ${CYAN}│${NC}\n" "$tyest"
printf  "${CYAN}│${NC} ${IWhite}THIS MONTH    ${NC}: ${r}%-34s${NC} ${CYAN}│${NC}\n" "$tmon"
echo -e "${CYAN}╰${line}╯${NC}"

echo -e "${CYAN}╭${short}╮${NC}"
echo -e "${CYAN}│${NC} ${y}Version${NC} : v7fix-1.0                       ${CYAN}│${NC}"
echo -e "${CYAN}│${NC} ${y}User   ${NC} : $LICENSE_OWNER"
echo -e "${CYAN}│${NC} ${y}Expired${NC} : $SCRIPT_EXP ($SCRIPT_ACTIVE)"
echo -e "${CYAN}╰${short}╯${NC}"

echo -e " ${KIRI}${a} ${KANAN}"
echo -e "${IWhite}"
read -rp " Pilih opsi [ 1 - 14 ] >> " opt

case $opt in
    1)  clear; menu-ssh ;;
    2)  clear; menu-vmess ;;
    3)  clear; menu-vless ;;
    4)  clear; menu-trojan ;;
    5)  clear; menu-set ;;
    6)
        clear
        updatemenu
        echo ""
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
        menu
        ;;
    7)  clear; running ;;
    8)  clear; change_banner ;;
    9)  clear; menu-backup ;;
    10)
        clear
        echo -e "${y}[WARN]${NC} Anda akan mendownload installer UDP dari Google Drive."
        echo -e "       Pastikan link masih dipercaya. Tekan Ctrl+C untuk batal."
        if v7_confirm "Lanjut download & install?"; then
            UDPX="https://docs.google.com/uc?export=download&id=1S3IE25v_fyUfCLslnujFBSBMNunDHDk2"
            tmp=$(mktemp /tmp/install-udp.XXXXXX)
            if wget -q -O "$tmp" "$UDPX" && [ -s "$tmp" ]; then
                chmod +x "$tmp"
                "$tmp" || warn "Installer UDP exit dengan error."
                rm -f "$tmp"
            else
                rm -f "$tmp"
                fail "Gagal download installer UDP."
            fi
        fi
        echo ""
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
        menu
        ;;
    11) clear; addhost ;;
    12) clear; show_license_info ;;
    13) clear; exit 0 ;;
    14) clear; menu-bot ;;
    *)  clear; menu ;;
esac
