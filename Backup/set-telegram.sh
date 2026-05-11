#!/bin/bash

clear
mkdir -p /etc/Anggun

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "        SET TELEGRAM BACKUP        "
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Masukkan BOT TOKEN dari @BotFather"
echo "Contoh: 123456789:ABCDEFxxxxxxxx"
echo ""
read -rp "BOT TOKEN : " bot_token
echo ""
echo "Masukkan CHAT ID Telegram"
echo "Bisa chat pribadi / grup / channel"
echo ""
read -rp "CHAT ID   : " chat_id

if [ -z "$bot_token" ] || [ -z "$chat_id" ]; then
    echo ""
    echo "BOT TOKEN / CHAT ID tidak boleh kosong."
    sleep 2
    menu-backup
    exit
fi

echo "$bot_token" > /etc/Anggun/bot-token
echo "$chat_id" > /etc/Anggun/chat-id

chmod 600 /etc/Anggun/bot-token /etc/Anggun/chat-id

echo ""
echo "Testing kirim pesan ke Telegram..."

curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
    -d chat_id="$chat_id" \
    -d text="✅ Telegram Backup berhasil dikonfigurasi di VPS." >/tmp/telegram-test.log 2>&1

if grep -q '"ok":true' /tmp/telegram-test.log; then
    echo ""
    echo "Berhasil! BOT TOKEN dan CHAT ID valid."
else
    echo ""
    echo "Gagal test Telegram."
    echo "Cek ulang BOT TOKEN / CHAT ID."
    echo ""
    cat /tmp/telegram-test.log
fi

rm -f /tmp/telegram-test.log

echo ""
read -n 1 -s -r -p "Press any key to back"
menu-backup
