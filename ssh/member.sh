#!/bin/bash
# ============================================================================
# v7fix — list SSH members
# Fixes vs gipalok:
#   - Removed dead code (curl google for date)
#   - Defined RED/GREEN/NORMAL (was empty in original)
#   - Uses lib/common.sh
# ============================================================================

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

NORMAL='\033[0m'

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m                 MEMBER SSH                 \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo "USERNAME          EXP DATE          STATUS"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

while IFS= read -r line; do
    AKUN="$(echo "$line" | cut -d: -f1)"
    ID="$(echo "$line" | cut -d: -f3)"
    [ -z "$ID" ] && continue
    [ "$ID" -lt 1000 ] 2>/dev/null && continue
    [ "$AKUN" = "nobody" ] && continue

    exp="$(chage -l "$AKUN" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')"
    status="$(passwd -S "$AKUN" 2>/dev/null | awk '{print $2}')"

    if [ "$status" = "L" ]; then
        printf "%-17s %2s %-17s %b%s%b\n" "$AKUN" "$exp     " "" "${RED}LOCKED${NORMAL}" "" ""
    else
        printf "%-17s %2s %-17s %b%s%b\n" "$AKUN" "$exp     " "" "${GREEN}UNLOCKED${NORMAL}" "" ""
    fi
done < /etc/passwd

JUMLAH=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo "Account number: $JUMLAH user"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali"
menu-ssh 2>/dev/null || menu
