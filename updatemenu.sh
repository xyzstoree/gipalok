#!/bin/bash
# ==========================================================
# UPDATE SCRIPT GIPALOK
# Repo: https://github.com/xyzstoree/gipalok
# ==========================================================

set +e

REPO_GIT="https://github.com/xyzstoree/gipalok.git"
REPO_RAW="https://raw.githubusercontent.com/xyzstoree/gipalok/main"
BASE_DIR="/root/gipalok"

NC='\033[0m'; RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'

OK_LIST=(); MISS_LIST=(); FAIL_LIST=()

info() { echo -e "${CYAN}[ INFO ]${NC} $1"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $1"; OK_LIST+=("$1"); }
warn() { echo -e "${YELLOW}[ WARN ]${NC} $1"; }
fail() { echo -e "${RED}[ FAIL ]${NC} $1"; FAIL_LIST+=("$1"); }
miss() { echo -e "${YELLOW}[ MISS ]${NC} $1"; MISS_LIST+=("$1"); }

need_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "Jalankan sebagai root."; exit 1
    fi
}

install_deps() {
    info "Cek dependency ringan..."
    NEED_INSTALL=0
    for pkg in curl wget git jq zip unzip cron at; do
        dpkg -s "$pkg" >/dev/null 2>&1 || NEED_INSTALL=1
    done
    if [ "$NEED_INSTALL" = "1" ]; then
        apt update -y >/dev/null 2>&1 || true
        apt install -y curl wget git jq zip unzip cron at >/dev/null 2>&1 || true
    fi
    systemctl enable --now cron >/dev/null 2>&1 || true
    systemctl enable --now atd  >/dev/null 2>&1 || true
}

prepare_repo() {
    info "Update Script dari GitHub..."

    # FIX: Cek apakah remote origin sudah mengarah ke repo yang benar.
    # Kalau repo lama (sudah dihapus) masih ada di /root/gipalok, git fetch
    # akan gagal diam-diam (|| true) dan file lama tetap dipakai.
    # Solusi: bandingkan URL remote dengan REPO_GIT — kalau beda, hapus dan clone ulang.
    NEED_CLONE=0
    if [ -d "$BASE_DIR/.git" ]; then
        CURRENT_REMOTE=$(git -C "$BASE_DIR" remote get-url origin 2>/dev/null || echo "")
        if [ "$CURRENT_REMOTE" != "$REPO_GIT" ]; then
            warn "Remote origin berbeda ($CURRENT_REMOTE) — hapus folder lama dan clone ulang..."
            NEED_CLONE=1
        fi
    else
        NEED_CLONE=1
    fi

    if [ "$NEED_CLONE" = "1" ]; then
        rm -rf "$BASE_DIR"
        info "Clone repo dari $REPO_GIT ..."
        git clone "$REPO_GIT" "$BASE_DIR" 2>&1 | tail -3 || { fail "Gagal clone repo"; exit 1; }
    fi

    cd "$BASE_DIR" || exit 1

    # Pastikan fetch berhasil sebelum reset
    if ! git fetch origin 2>/dev/null; then
        fail "Gagal fetch dari GitHub. Cek koneksi internet VPS kamu."
        exit 1
    fi
    git reset --hard origin/main
    info "Repo berhasil diperbarui ke commit terbaru."
}

download_raw() {
    curl -fsSL "${REPO_RAW}/$1" -o "$2" >/dev/null 2>&1
}

install_file() {
    local src="$1"; local dst="$2"; local name="$3"
    [ -z "$name" ] && name="$(basename "$dst")"
    mkdir -p "$(dirname "$dst")"

    if [ -f "$BASE_DIR/$src" ]; then
        cp "$BASE_DIR/$src" "$dst" >/dev/null 2>&1
    else
        warn "File tidak ada di repo lokal: $src"
        download_raw "$src" "$dst"
    fi

    if [ -s "$dst" ]; then
        chmod +x "$dst" >/dev/null 2>&1 || true
        ok "Installed: $dst"
    else
        rm -f "$dst" >/dev/null 2>&1 || true
        miss "$name (src=$src)"
    fi
}

install_all() {
    info "Memasang command ke /usr/bin..."

    # ===== MENU UTAMA =====
    install_file "Menu/menu.sh"          /usr/bin/menu          "menu"
    install_file "Menu/menu-ssh.sh"      /usr/bin/menu-ssh      "menu-ssh"
    install_file "Menu/menu-vmess.sh"    /usr/bin/menu-vmess    "menu-vmess"
    install_file "Menu/menu-vless.sh"    /usr/bin/menu-vless    "menu-vless"
    install_file "Menu/menu-trojan.sh"   /usr/bin/menu-trojan   "menu-trojan"
    install_file "Menu/menu-trgo.sh"     /usr/bin/menu-trgo     "menu-trgo"
    install_file "Menu/menu-set.sh"      /usr/bin/menu-set      "menu-set"
    install_file "Menu/menu-bot.sh"      /usr/bin/menu-bot      "menu-bot"
    install_file "Menu/menu-domain.sh"   /usr/bin/menu-domain   "menu-domain"
    install_file "Menu/menu-webmin.sh"   /usr/bin/menu-webmin   "menu-webmin"
    install_file "Menu/menu-trial.sh"    /usr/bin/menu-trial    "menu-trial"

    # ===== MENU SISTEM =====
    install_file "Menu/About.sh"         /usr/bin/about         "about"
    install_file "Menu/auto-reboot.sh"   /usr/bin/auto-reboot   "auto-reboot"
    install_file "Menu/bw.sh"            /usr/bin/bw            "bw"
    install_file "Menu/restart.sh"       /usr/bin/restart       "restart"
    install_file "Menu/running.sh"       /usr/bin/running       "running"
    install_file "Menu/clearcache.sh"    /usr/bin/clearcache    "clearcache"
    install_file "Menu/clearlog.sh"      /usr/bin/clearlog      "clearlog"
    install_file "Menu/mbot.sh"          /usr/bin/mbot          "mbot"

    # ===== PORT =====
    install_file "Port/Port-change.sh"   /usr/bin/port-change   "port-change"
    install_file "Port/port-ssl.sh"      /usr/bin/port-ssl      "port-ssl"
    install_file "Port/port-ovpn.sh"     /usr/bin/port-ovpn     "port-ovpn"
    install_file "Port/port-tr.sh"       /usr/bin/port-tr       "port-tr"

    # ===== SSH / OPENSSH (NAMA FILE ASLI DI REPO) =====
    install_file "ssh/usernew.sh"        /usr/bin/usernew       "usernew"
    install_file "ssh/trial.sh"          /usr/bin/trial         "trial"
    install_file "ssh/renew.sh"          /usr/bin/renew         "renew"
    install_file "ssh/delete.sh"         /usr/bin/delete        "delete"
    install_file "ssh/hapus.sh"          /usr/bin/hapus         "hapus"
    install_file "ssh/cek.sh"            /usr/bin/cek           "cek"
    install_file "ssh/member.sh"         /usr/bin/member        "member"
    install_file "ssh/autokill.sh"       /usr/bin/autokill      "autokill"
    install_file "ssh/ceklim.sh"         /usr/bin/ceklim        "ceklim"
    install_file "ssh/tendang.sh"        /usr/bin/tendang       "tendang"
    install_file "ssh/add-host.sh"       /usr/bin/add-host      "add-host"
    install_file "ssh/cf.sh"             /usr/bin/cf            "cf"
    install_file "ssh/genssl.sh"         /usr/bin/genssl        "genssl"
    install_file "ssh/xp.sh"             /usr/bin/xp            "xp"
    install_file "ssh/user-lock.sh"      /usr/bin/user-lock     "user-lock"
    install_file "ssh/user-unlock.sh"    /usr/bin/user-unlock   "user-unlock"
    install_file "ssh/bbr.sh"            /usr/bin/bbr           "bbr"
    install_file "ssh/speedtest.sh"      /usr/bin/speedtest     "speedtest"

    # ===== XRAY VMESS =====
    install_file "xray/add-ws.sh"        /usr/bin/add-ws        "add-ws"
    install_file "xray/trialvmess.sh"    /usr/bin/trial-ws      "trial-ws"
    install_file "xray/renew-ws.sh"      /usr/bin/renew-ws      "renew-ws"
    install_file "xray/del-ws.sh"        /usr/bin/del-ws        "del-ws"
    install_file "xray/cek-ws.sh"        /usr/bin/cek-ws        "cek-ws"

    # ===== XRAY VLESS =====
    install_file "xray/add-vless.sh"     /usr/bin/add-vless     "add-vless"
    install_file "xray/trialvless.sh"    /usr/bin/trial-vless   "trial-vless"
    install_file "xray/renew-vless.sh"   /usr/bin/renew-vless   "renew-vless"
    install_file "xray/del-vless.sh"     /usr/bin/del-vless     "del-vless"
    install_file "xray/cek-vless.sh"     /usr/bin/cek-vless     "cek-vless"

    # ===== XRAY TROJAN =====
    install_file "xray/add-tr.sh"        /usr/bin/add-tr        "add-tr"
    install_file "xray/trialtrojan.sh"   /usr/bin/trial-tr      "trial-tr"
    install_file "xray/renew-tr.sh"      /usr/bin/renew-tr      "renew-tr"
    install_file "xray/del-tr.sh"        /usr/bin/del-tr        "del-tr"
    install_file "xray/cek-tr.sh"        /usr/bin/cek-tr        "cek-tr"

    # ===== TROJAN GO =====
    install_file "xray/addtrgo.sh"       /usr/bin/addtrgo       "addtrgo"
    install_file "xray/trialtrojango.sh" /usr/bin/trialtrojango "trialtrojango"
    install_file "xray/renewtrgo.sh"     /usr/bin/renewtrgo     "renewtrgo"
    install_file "xray/deltrgo.sh"       /usr/bin/deltrgo       "deltrgo"
    install_file "xray/cektrgo.sh"       /usr/bin/cektrgo       "cektrgo"

    # ===== BACKUP =====
    install_file "Backup/menu-backup.sh" /usr/bin/menu-backup   "menu-backup"
    install_file "Backup/set-telegram.sh" /usr/bin/set-telegram "set-telegram"
    install_file "Backup/backup.sh"      /usr/bin/backup        "backup"
    install_file "Backup/restore.sh"     /usr/bin/restore       "restore"
    install_file "Backup/autobackup.sh"  /usr/bin/autobackup    "autobackup"
    install_file "Backup/set-br.sh"      /usr/bin/set-br        "set-br"
    install_file "Backup/strt.sh"        /usr/bin/strt          "strt"
    install_file "Backup/limitspeed.sh"  /usr/bin/limitspeed    "limitspeed"

    # ===== BOT API =====
    install_file "api/install-api.sh"    /usr/bin/install-api   "install-api"

    # ===== QUEUE / LIMIT IP =====
    install_file "Queue/Queue-ip-ssh.sh"     /usr/bin/limitssh     "limitssh"
    install_file "Queue/Queue-ip-vmess.sh"   /usr/bin/limitvmess   "limitvmess"
    install_file "Queue/Queue-ip-vless.sh"   /usr/bin/limitvless   "limitvless"
    install_file "Queue/Queue-ip-trojan.sh"  /usr/bin/limittrojan  "limittrojan"

    # alias dash agar menu lama tetap jalan
    cp /usr/bin/limitssh    /usr/bin/limit-ssh    2>/dev/null || true
    cp /usr/bin/limitvmess  /usr/bin/limit-vmess  2>/dev/null || true
    cp /usr/bin/limitvless  /usr/bin/limit-vless  2>/dev/null || true
    cp /usr/bin/limittrojan /usr/bin/limit-trojan 2>/dev/null || true
    chmod +x /usr/bin/limit-ssh /usr/bin/limit-vmess /usr/bin/limit-vless /usr/bin/limit-trojan 2>/dev/null || true

    # ===== QUEUE / QUOTA =====
    install_file "Queue/quota-vmess-ws.sh"        /usr/bin/quota-vmess-ws        "quota-vmess-ws"
    install_file "Queue/quota-vless-ws.sh"        /usr/bin/quota-vless-ws        "quota-vless-ws"
    install_file "Queue/quota-trojan-ws.sh"       /usr/bin/quota-trojan-ws       "quota-trojan-ws"
    install_file "Queue/quota-vmess-grpc.sh"      /usr/bin/quota-vmess-grpc      "quota-vmess-grpc"
    install_file "Queue/quota-trojan-grpc.sh"     /usr/bin/quota-trojan-grpc     "quota-trojan-grpc"
    install_file "Queue/quota-vmess-ws-orbit.sh"  /usr/bin/quota-vmess-ws-orbit  "quota-vmess-ws-orbit"
    install_file "Queue/quota-vmess-ws-orbit1.sh" /usr/bin/quota-vmess-ws-orbit1 "quota-vmess-ws-orbit1"
    install_file "Queue/Queue-quota-vmess.sh"     /usr/bin/Queue-quota-vmess     "Queue-quota-vmess"
    install_file "Queue/Queue-quota-vless.sh"     /usr/bin/Queue-quota-vless     "Queue-quota-vless"
    install_file "Queue/quota.sh"                 /usr/bin/quota                 "quota"
    install_file "Queue/Queue.sh"                 /usr/bin/Queue                 "Queue"
    install_file "Queue/loop.sh"                  /usr/bin/loop                  "loop"
    install_file "Queue/matikan.sh"               /usr/bin/matikan               "matikan"
    install_file "Queue/cek-ssh.sh"               /usr/bin/cek-ssh               "cek-ssh"
    install_file "Queue/mesinssh.sh"              /usr/bin/mesinssh              "mesinssh"
    install_file "Queue/nskk.sh"                  /usr/bin/nskk                  "nskk"

    # ===== UPDATE SELF =====
    install_file "updatemenu.sh"         /usr/bin/updatemenu    "updatemenu"
}

fix_permissions() {
    info "Memasang chmod ke /usr/bin..."
    chmod +x /usr/bin/menu* 2>/dev/null || true
    chmod +x /usr/bin/add-* /usr/bin/trial* /usr/bin/renew* /usr/bin/del-* /usr/bin/cek-* 2>/dev/null || true
    chmod +x /usr/bin/backup /usr/bin/restore /usr/bin/autobackup /usr/bin/set-telegram /usr/bin/menu-backup 2>/dev/null || true
    chmod +x /usr/bin/quota* /usr/bin/limit* /usr/bin/Queue /usr/bin/loop /usr/bin/matikan 2>/dev/null || true
    chmod +x /usr/bin/port-* /usr/bin/install-api /usr/bin/about 2>/dev/null || true
    hash -r 2>/dev/null || true
}

summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}        UPDATE SCRIPT SELESAI${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Repo   : $REPO_GIT"
    echo -e "Folder : $BASE_DIR"
    echo -e "OK     : ${#OK_LIST[@]}"
    echo -e "MISS   : ${#MISS_LIST[@]}"
    echo -e "FAIL   : ${#FAIL_LIST[@]}"
    for item in "${MISS_LIST[@]}"; do echo -e "${YELLOW}[ MISS ]${NC} $item"; done
    for item in "${FAIL_LIST[@]}"; do echo -e "${RED}[ FAIL ]${NC} $item"; done
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

return_menu() {
    echo ""
    echo -e "${GREEN}[ INFO ]${NC} Proses update selesai."
    sleep 2
    command -v menu >/dev/null 2>&1 && menu
}

main() {
    clear
    need_root
    install_deps
    prepare_repo
    install_all
    fix_permissions
    summary
    return_menu
}

main "$@"
