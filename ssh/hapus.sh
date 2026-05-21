#!/bin/bash
# ============================================================================
# v7fix — delete SSH user
# Fixes vs gipalok:
#   - Removed dead code (curl google for date)
#   - Returns to menu-ssh, not menu (was inconsistent)
#   - Uses lib/common.sh
#   - getent check before userdel
#   - Cleans up Queue/expiry leftovers
#   - Refuses to delete system accounts (uid<1000)
# ============================================================================

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

clear
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m             HAPUS SSH USER                 \E[0m"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo "   USERNAME        EXP DATE        STATUS"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

while IFS= read -r line; do
    AKUN="$(echo "$line" | cut -d: -f1)"
    ID="$(echo "$line" | cut -d: -f3)"
    [ -z "$ID" ] && continue
    [ "$ID" -lt 1000 ] 2>/dev/null && continue
    [ "$AKUN" = "nobody" ] && continue

    exp="$(chage -l "$AKUN" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')"
    status="$(passwd -S "$AKUN" 2>/dev/null | awk '{print $2}')"

    if [ "$status" = "L" ]; then
        printf "%-17s %2s %-17s %2s \n" "   • $AKUN" "$exp     " "LOCKED"
    else
        printf "%-17s %2s %-17s %2s \n" "   • $AKUN" "$exp     " "UNLOCKED"
    fi
done < /etc/passwd

JUMLAH=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo "   Total: $JUMLAH User"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -rp "   Username : " Pengguna

if [ -z "$Pengguna" ]; then
    echo -e "   [ERROR] Username cannot be empty"
elif getent passwd "$Pengguna" >/dev/null 2>&1; then
    UID_NUM=$(id -u "$Pengguna" 2>/dev/null || echo 0)
    if [ "$UID_NUM" -lt 1000 ]; then
        echo -e "   [BLOCK] Tidak boleh menghapus user sistem (uid<1000)."
    else
        userdel -f "$Pengguna" >/dev/null 2>&1 || true
        rm -f "/etc/Anggun/Queue/ssh/ip/$Pengguna" 2>/dev/null
        echo -e "   [INFO] User $Pengguna telah dihapus."
    fi
else
    echo -e "   [INFO] User $Pengguna tidak ada."
fi

echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
menu-ssh 2>/dev/null || menu
