#!/bin/bash
# FIX 1: Removed dead code — curl google date (slow, fragile, $biji variable never used)
# FIX 2: Date format changed from +%Y/%m/%d → +%Y-%m-%d (usermod -e requires YYYY-MM-DD)
# FIX 3: Added validation for empty/non-numeric Days input
# FIX 4: egrep "^$User" → egrep "^${User}:" to prevent partial username match
clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m               RENEW  USER                \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo
read -p "Username : " User

if [ -z "$User" ]; then
    echo "Username tidak boleh kosong."
    sleep 2
    menu-ssh 2>/dev/null || menu
    exit 1
fi

# FIX: Use ^${User}: to prevent partial match (e.g. "john" matching "johnwick")
if ! egrep -q "^${User}:" /etc/passwd; then
    clear
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;41;36m               RENEW  USER                \E[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    echo -e "   Username '$User' tidak ditemukan."
    echo -e ""
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
    menu-ssh 2>/dev/null || menu
    exit 1
fi

read -p "Day Extend : " Days

# FIX: Validate Days is a positive integer
if ! echo "$Days" | grep -Eq '^[0-9]+$' || [ "$Days" -lt 1 ]; then
    echo "Jumlah hari harus angka positif. Contoh: 30"
    sleep 2
    menu-ssh 2>/dev/null || menu
    exit 1
fi

# FIX: Simplified date calculation — use date -d directly instead of epoch math
# FIX: Format changed from +%Y/%m/%d to +%Y-%m-%d (usermod -e requires YYYY-MM-DD)
Expiration=$(date -d "+${Days} days" +%Y-%m-%d)
Expiration_Display=$(date -d "+${Days} days" '+%d %b %Y')

passwd -u "$User" 2>/dev/null || true
usermod -e "$Expiration" "$User"

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m               RENEW  USER                \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " Username   : $User"
echo -e " Days Added : $Days Days"
echo -e " Expires on : $Expiration_Display"
echo -e ""
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
menu-ssh 2>/dev/null || menu
