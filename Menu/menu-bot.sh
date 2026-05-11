#!/bin/bash

clear

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'

API_SERVICE="botvpn-api"
API_TOKEN_FILE="/etc/Anggun/api-token"
API_PORT="5889"
REPO_DIR="/root/gipalok"

install_api_bot() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}          PLUGIN API BOT           ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Menginstall paket yang dibutuhkan..."
    echo ""

    if [ -x "$REPO_DIR/api/install-api.sh" ]; then
        bash "$REPO_DIR/api/install-api.sh"
    else
        echo -e "${RED}[ERROR]${NC} File install API tidak ditemukan:"
        echo "$REPO_DIR/api/install-api.sh"
        echo ""
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
        menu-bot
        exit 1
    fi

    echo ""
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
    menu-bot
}

cek_api_bot() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}             CEK API BOT           ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo "Service status:"
    systemctl status botvpn-api --no-pager -l 2>/dev/null | head -20 || echo "Service botvpn-api belum ada."
    echo ""

    echo "Port listen:"
    ss -tulpn | grep ":$API_PORT" || echo "Port $API_PORT belum listen."
    echo ""

    echo "API token:"
    if [ -s "$API_TOKEN_FILE" ]; then
        cat "$API_TOKEN_FILE"
    else
        echo "Token belum ada."
    fi
    echo ""

    echo "Health check:"
    curl -s "http://127.0.0.1:$API_PORT/health" || echo "API belum merespon."
    echo ""

    echo ""
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
    menu-bot
}

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}             SETUP BOT             ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Plugin API Bot"
echo "2. Cek API Bot"
echo "3. Back To Menu"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -rp "Pilih Nomor: " opt

case $opt in
    1) install_api_bot ;;
    2) cek_api_bot ;;
    3) clear ; menu ;;
    *) clear ; menu-bot ;;
esac
