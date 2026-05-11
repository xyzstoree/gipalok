#!/bin/bash

clear

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "             AUTO BACKUP           "
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1). Aktifkan Auto Backup Harian"
echo "2). Nonaktifkan Auto Backup"
echo "3). Cek Status Auto Backup"
echo "4). Back"
echo ""
read -rp "Pilih Nomor: " opt

case $opt in
    1)
        echo ""
        read -rp "Jam backup otomatis? Contoh 00, 03, 23 : " jam
        [ -z "$jam" ] && jam="00"

        if ! echo "$jam" | grep -Eq '^[0-9]{1,2}$'; then
            echo "Format jam salah."
            sleep 2
            autobackup
            exit
        fi

        if [ "$jam" -lt 0 ] || [ "$jam" -gt 23 ]; then
            echo "Jam harus 0-23."
            sleep 2
            autobackup
            exit
        fi

        crontab -l 2>/dev/null | grep -v "/usr/bin/backup" > /tmp/cron-backup || true
        echo "0 $jam * * * /usr/bin/backup >/var/log/autobackup.log 2>&1" >> /tmp/cron-backup
        crontab /tmp/cron-backup
        rm -f /tmp/cron-backup

        echo ""
        echo "Auto backup aktif setiap jam $jam:00"
        ;;
    2)
        crontab -l 2>/dev/null | grep -v "/usr/bin/backup" > /tmp/cron-backup || true
        crontab /tmp/cron-backup
        rm -f /tmp/cron-backup

        echo ""
        echo "Auto backup dinonaktifkan."
        ;;
    3)
        echo ""
        echo "Cron backup:"
        crontab -l 2>/dev/null | grep "/usr/bin/backup" || echo "Auto backup belum aktif."
        echo ""
        echo "Log terakhir:"
        tail -n 20 /var/log/autobackup.log 2>/dev/null || echo "Belum ada log."
        ;;
    4)
        menu-backup
        exit
        ;;
    *)
        autobackup
        exit
        ;;
esac

echo ""
read -n 1 -s -r -p "Press any key to back"
menu-backup
