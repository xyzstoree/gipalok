#!/bin/bash
# ============================================================================
# v7fix — main setup
# Repo: https://github.com/xyzstoree/v7fix
# Logs: /var/log/v7fix/install.log
# ============================================================================
set +e

REPO_GIT="https://github.com/xyzstoree/v7fix.git"
BASE_DIR="/root/v7fix"
LOG_FILE="/var/log/v7fix/install.log"

mkdir -p /var/log/v7fix
exec > >(tee -a "$LOG_FILE") 2>&1
echo ""
echo "===== v7fix install — $(date) ====="

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Script harus dijalankan sebagai root."
    exit 1
fi

echo_info()    { echo -e "\033[1;36m[INFO]\033[0m $*"; }
echo_success() { echo -e "\033[1;32m[ OK ]\033[0m $*"; }
echo_error()   { echo -e "\033[1;31m[FAIL]\033[0m $*"; }

# ---------------------------------------------------------------------------
# Step 1: Apt prereqs (so we can clone & jq the manifest)
# ---------------------------------------------------------------------------
echo_info "Apt update + base deps..."
apt update -y >/dev/null 2>&1 || true
DEBIAN_FRONTEND=noninteractive apt install -y \
    curl wget git unzip screen nano jq sudo ruby figlet \
    iptables iptables-persistent netfilter-persistent vnstat cron at \
    python3 python3-pip uuid-runtime >/dev/null 2>&1 \
    || { echo_error "apt install gagal — cek koneksi & repository."; exit 1; }

# ---------------------------------------------------------------------------
# Step 2: Clone or refresh repo
# ---------------------------------------------------------------------------
echo_info "Siapkan repo di $BASE_DIR..."
if [ -d "$BASE_DIR/.git" ]; then
    current=$(git -C "$BASE_DIR" remote get-url origin 2>/dev/null || echo "")
    if [ "$current" != "$REPO_GIT" ]; then
        rm -rf "$BASE_DIR"
        git clone "$REPO_GIT" "$BASE_DIR" || { echo_error "git clone gagal"; exit 1; }
    else
        git -C "$BASE_DIR" fetch origin && git -C "$BASE_DIR" reset --hard origin/main
    fi
else
    rm -rf "$BASE_DIR"
    git clone "$REPO_GIT" "$BASE_DIR" || { echo_error "git clone gagal"; exit 1; }
fi

cd "$BASE_DIR" || exit 1
find . -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# ---------------------------------------------------------------------------
# Step 3: Install lib/ to /etc/v7fix/lib (so other scripts can source)
# ---------------------------------------------------------------------------
echo_info "Install lib/ ke /etc/v7fix/lib ..."
mkdir -p /etc/v7fix/lib
cp lib/common.sh  /etc/v7fix/lib/common.sh
cp lib/license.sh /etc/v7fix/lib/license.sh
chmod 644 /etc/v7fix/lib/*.sh

# Source common.sh now that it's installed, so subsequent steps benefit
# shellcheck source=/dev/null
source /etc/v7fix/lib/common.sh

# ---------------------------------------------------------------------------
# Step 4: License gate before any further install — blocks unregistered VPS
# ---------------------------------------------------------------------------
echo_info "Cek izin akses dari xyzstoree/izin ..."
# shellcheck source=/dev/null
source /etc/v7fix/lib/license.sh
v7_license_check  # exits 2 if denied

# ---------------------------------------------------------------------------
# Step 5: Required directories
# ---------------------------------------------------------------------------
echo_info "Bikin direktori state..."
mkdir -p /var/lib/Anggun /etc/Anggun /etc/xray /var/log/xray /etc/iptables \
         /var/cache/v7fix
touch /root/log-install.txt

# ---------------------------------------------------------------------------
# Step 6: Tools, xray, ssh, ssh-ws
# ---------------------------------------------------------------------------
run_step() {
    local name="$1"; shift
    echo_info "==> $name"
    if "$@"; then
        echo_success "$name selesai"
    else
        echo_error "$name gagal — lanjut step berikutnya. Log: $LOG_FILE"
    fi
}

run_step "Install dependencies (tools.sh)" bash tools.sh
run_step "Install Xray (xray/ins-xray.sh)" bash xray/ins-xray.sh
run_step "Setup OpenSSH (ssh/ssh-vpn.sh)"  bash ssh/ssh-vpn.sh
run_step "Setup SSH WebSocket (sshws/insshws.sh)" bash sshws/insshws.sh
run_step "Install command (updatemenu.sh)" bash updatemenu.sh

# ---------------------------------------------------------------------------
# Step 7: Auto-menu on root login
# ---------------------------------------------------------------------------
echo_info "Aktifkan auto-menu di login root..."
if ! grep -q "AUTO_MENU_SHOWN" /root/.bashrc 2>/dev/null; then
cat >> /root/.bashrc <<'EOF'

# v7fix: auto open menu on root SSH login
if [[ $- == *i* ]] && [ -z "$AUTO_MENU_SHOWN" ]; then
    export AUTO_MENU_SHOWN=1
    if command -v menu >/dev/null 2>&1; then
        menu
        exit
    fi
fi
EOF
fi

# ---------------------------------------------------------------------------
# Step 8: Clear log (best effort)
# ---------------------------------------------------------------------------
[ -x clearlog.sh ] && bash clearlog.sh

# ---------------------------------------------------------------------------
# Step 9: iptables open ports
# ---------------------------------------------------------------------------
echo_info "Buka port di iptables..."
for port in 22 80 443 109 110 143 447 500 777 8080 8880 2082 2083 2086 8443 5889; do
    iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || \
        iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
done
netfilter-persistent save 2>/dev/null \
    || iptables-save > /etc/iptables/rules.v4 2>/dev/null \
    || true

# ---------------------------------------------------------------------------
# Step 10: Enable services
# ---------------------------------------------------------------------------
for svc in ssh xray nginx dropbear ws cron vnstat netfilter-persistent atd; do
    systemctl enable "$svc" 2>/dev/null || true
done

echo ""
echo_success "============================================================"
echo_success " v7fix install selesai. Log: $LOG_FILE"
echo_success " Login ulang akan otomatis membuka menu."
echo_success " Untuk setup API Bot:  menu > 14 > 1"
echo_success "============================================================"
