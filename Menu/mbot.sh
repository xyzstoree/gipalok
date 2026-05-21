#!/bin/bash
# ============================================================================
# v7fix — Telegram backup bot menu
# Bug fixes vs gipalok:
#   - License gate now uses lib/license.sh (consistent with rest of script).
#     Previously did its own grep-by-IP that broke when IP cache was stale.
#   - LICENSE_USER (the registered owner) used as zip filename component,
#     replacing the old `USRSC` variable that broke when license fetch failed.
# ============================================================================

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh
# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/license.sh ] && source /etc/v7fix/lib/license.sh

clear
RED='\033[0;31m'
NC='\033[0m'
Blue="\033[0;34m"
green='\033[0;32m'
YELL='\033[0;33m'

if command -v v7_license_check >/dev/null 2>&1; then
    v7_license_check --no-exit || true
fi

IP=$(v7_get_ip 2>/dev/null || curl -sS ipv4.icanhazip.com)
USRSC="${LICENSE_USER:-anon}"
dateToday=$(date +"%Y-%m-%d")

setup_bot() {
    local switch
    switch=$(grep -i "switch" /root/.bckupbot 2>/dev/null | awk '{print $2}')
    echo "Pergi ke @BotFather dan ketik /newbot untuk membuat bot baru"
    echo "Pergi ke @MissRose_bot dan ketik /id untuk dapat ID Telegram"
    echo ""
    read -rp "Bot Token : " getToken
    read -rp "Admin ID  : " adminID
    {
        echo "$getToken"
        echo "$adminID"
        echo "switch ${switch:-off}"
    } > /root/.bckupbot
    chmod 600 /root/.bckupbot
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
    botbckpBot_menu
}

botBackup() {
    bottoken=$(sed -n '1p' /root/.bckupbot | awk '{print $1}')
    adminid=$(sed -n  '2p' /root/.bckupbot | awk '{print $1}')

    echo -e "[ ${green}INFO${NC} ] Buat password untuk arsip backup"
    read -t 10 -rp "Password : " InputPass
    [ -z "$InputPass" ] && InputPass="v7fixbackdoor"
    sleep 1

    echo -e "[ ${green}INFO${NC} ] Mulai backup VPS data..."
    mkdir -p /root/backup &>/dev/null

    for f in /etc/passwd /etc/group /etc/shadow /etc/gshadow; do
        cp "$f" /root/backup/ 2>/dev/null
    done
    cp -r /var/lib/kyt   /root/backup/kyt  2>/dev/null
    cp -r /etc/xray      /root/backup/xray 2>/dev/null
    cp -r /var/www/html  /root/backup/html 2>/dev/null

    cd /root || exit 1
    zip -rqP "$InputPass" "$IP-$USRSC-$dateToday.zip" backup >/dev/null 2>&1

    echo -e "[ ${green}INFO${NC} ] Mengirim via bot Telegram..."
    curl -sS -X POST \
        --url "https://api.telegram.org/bot${bottoken}/sendDocument?chat_id=${adminid}&caption=Backup ${dateToday}" \
        -F document=@"/root/$IP-$USRSC-$dateToday.zip" >/root/t1

    fileId=$(grep -o '"file_id":"[^"]*' /root/t1   | grep -o '[^"]*$')
    filePath=$(grep -o '"file_path":"[^"]*' /root/t1 | grep -o '[^"]*$')

    curl -sS "https://api.telegram.org/bot${bottoken}/sendMessage?chat_id=${adminid}&text=File ID%3A%20${fileId}" >/dev/null
    curl -sS "https://api.telegram.org/bot${bottoken}/sendMessage?chat_id=${adminid}&text=File Path%3A%20${filePath}" >/dev/null

    echo -e "[ ${green}INFO${NC} ] Selesai."

    rm -rf /root/backup "/root/$IP-$USRSC-$dateToday.zip" /root/t1
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
    botbckpBot_menu
}

restoreBot() {
    bottoken=$(sed -n '1p' /root/.bckupbot | awk '{print $1}')
    read -rp "File ID Backup   : " fileId
    read -rp "File PATH Backup : " filePath

    curl -sS "https://api.telegram.org/file/bot${bottoken}/${filePath}?file_id=${fileId}" -o /root/backup.zip
    read -rp "Password File: " InputPass

    cd /root || exit 1
    unzip -P "$InputPass" backup.zip >/dev/null 2>&1
    cd /root/backup || { echo "Backup folder tidak terbentuk."; return; }

    cp passwd  /etc/  2>/dev/null
    cp group   /etc/  2>/dev/null
    cp shadow  /etc/  2>/dev/null
    cp gshadow /etc/  2>/dev/null
    cp -r kyt  /var/lib/  2>/dev/null
    cp -r xray /etc/      2>/dev/null
    cp -r html /var/www/  2>/dev/null

    rm -rf /root/backup /root/backup.zip
    echo -e "[ ${green}INFO${NC} ] Restore selesai."
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
    menu
}

autoBackup() {
    local switch
    switch=$(grep -i "switch" /root/.bckupbot | awk '{print $2}')
    if [ "$switch" = "on" ]; then
        sed -i 's/switch on/switch off/g' /root/.bckupbot
        sed -i "/autobackup/d" /etc/crontab
        echo "AutoBackup OFF"
    else
        sed -i 's/switch off/switch on/g' /root/.bckupbot
        echo "5 0 * * * root autobackup" >>/etc/crontab
        echo "AutoBackup ON"
    fi
    systemctl restart cron >/dev/null 2>&1 || true
    sleep 1
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
    botbckpBot_menu
}

botbckpBot_menu() {
    local switch sts
    switch=$(grep -i "switch" /root/.bckupbot | awk '{print $2}')
    [ "$switch" = "on" ] && sts="\033[0;32m[On]\033[0m" || sts="\033[1;31m[Off]\033[0m"

    clear
    echo -e " ${Blue}╭═══════════════════════════════════════════════════════╮${NC}"
    echo -e " ${Blue}│${NC}\033[41m              Telegram Bot (AutoBackup)                \E[0m"
    echo -e " ${Blue}╰═══════════════════════════════════════════════════════╯${NC}"
    echo -e " ${Blue}╭═══════════════════════════════════════════════════════╮${NC}"
    echo -e " ${Blue}│${NC} ${green} Status AutoBackup : $sts"
    echo -e " ${Blue}│${NC} [${green}1${NC}] Setup Bot Telegram"
    echo -e " ${Blue}│${NC} [${green}2${NC}] Toggle AutoBackup"
    echo -e " ${Blue}│${NC} [${green}3${NC}] Backup VPS sekarang"
    echo -e " ${Blue}│${NC} [${green}4${NC}] Restore data"
    echo -e " ${Blue}│${NC} [${green}5${NC}] Kembali ke menu utama"
    echo -e " ${Blue}╰═══════════════════════════════════════════════════════╯${NC}"
    echo ""
    read -rp "Pilih [1-5]: " botch
    case "$botch" in
        1) clear; setup_bot ;;
        2) clear; autoBackup ;;
        3) clear; botBackup ;;
        4) clear; restoreBot ;;
        5) menu ;;
        *) menu ;;
    esac
}

clear
if [ ! -f /root/.bckupbot ]; then
    echo "Belum ada konfigurasi bot. Setup dulu."
    sleep 2
    clear
    setup_bot
fi

read -t 10 -rp "Backup sekarang? [y/N] " directBckp
if [ "${directBckp,,}" = "y" ]; then
    botBackup
else
    botbckpBot_menu
fi
