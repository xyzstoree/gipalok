#!/bin/bash
# ============================================================================
# AUTOSCRIPT VPS - SETUP UTAMA
# AUTHOR: XYZSTOREE
# ============================================================================

echo_info()    { echo -e "\033[1;36m[INFO]\033[0m $1"; }
echo_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
echo_error()   { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

if [[ $EUID -ne 0 ]]; then
   echo_error "Script ini harus dijalankan sebagai root!"
   exit 1
fi

REPO_GIT="https://github.com/xyzstoree/gipalok.git"
BASE_DIR="/root/gipalok"

echo_info "Update dan upgrade sistem..."
apt update && apt upgrade -y

echo_info "Menginstal dependencies dasar..."
apt install -y curl wget git unzip screen nano jq sudo lolcat figlet ruby \
    iptables-persistent netfilter-persistent vnstat cron python3 python3-pip uuid-runtime

# Pastikan repo ada di /root/gipalok (banyak script hardcode path ini)
echo_info "Menyiapkan repo di $BASE_DIR..."
if [ ! -d "$BASE_DIR/.git" ]; then
    rm -rf "$BASE_DIR"
    git clone "$REPO_GIT" "$BASE_DIR" || { echo_error "Gagal clone repo"; exit 1; }
else
    cd "$BASE_DIR" && git fetch origin && git reset --hard origin/main
fi

cd "$BASE_DIR" || exit 1
chmod +x setup.sh updatemenu.sh tools.sh clearlog.sh 2>/dev/null || true
find . -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo_info "Membuat direktori yang diperlukan..."
mkdir -p /var/lib/Anggun /etc/Anggun /etc/xray /var/log/xray /etc/iptables
touch /root/log-install.txt

echo_info "Menginstal tools dependencies..."
bash tools.sh

echo_info "Menginstal Xray dan konfigurasi..."
bash xray/ins-xray.sh

echo_info "Mengonfigurasi SSH..."
bash ssh/ssh-vpn.sh

echo_info "Mengonfigurasi SSH WebSocket..."
bash sshws/insshws.sh

echo_info "Mengupdate menu scripts..."
bash updatemenu.sh

echo_info "Mengaktifkan auto menu saat login root..."
if ! grep -q "AUTO_MENU_SHOWN" /root/.bashrc 2>/dev/null; then
cat >> /root/.bashrc <<'EOF'

# Auto open menu on root SSH login
if [[ $- == *i* ]] && [ -z "$AUTO_MENU_SHOWN" ]; then
    export AUTO_MENU_SHOWN=1
    if command -v menu >/dev/null 2>&1; then
        menu
        exit
    elif [ -x /usr/bin/menu ]; then
        /usr/bin/menu
        exit
    fi
fi
EOF
fi

echo_info "Membersihkan log files..."
bash clearlog.sh

echo_info "Konfigurasi iptables untuk membuka port..."
for port in 22 80 443 109 110 143 447 500 777 8080 8880 2082 2083 2086 8443 5889; do
    iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || \
        iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
done
netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

echo_info "Mengaktifkan layanan..."
for svc in ssh xray nginx dropbear ws cron vnstat netfilter-persistent; do
    systemctl enable $svc 2>/dev/null || true
done

echo_success "======================================"
echo_success " Setup selesai!"
echo_success " Login ulang akan langsung membuka menu."
echo_success " Untuk setup API Bot: menu > 14 > 1"
echo_success "======================================"
