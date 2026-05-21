#!/bin/bash
# ============================================================================
# v7fix — updatemenu (data-driven via install/manifest.txt)
# Repo: https://github.com/xyzstoree/v7fix
# ============================================================================
set +e

REPO_GIT="https://github.com/xyzstoree/v7fix.git"
REPO_RAW="https://raw.githubusercontent.com/xyzstoree/v7fix/main"
BASE_DIR="/root/v7fix"

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh
# shellcheck source=/dev/null
[ -f "$BASE_DIR/install/install_manifest.sh" ] && source "$BASE_DIR/install/install_manifest.sh"

need_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "Jalankan sebagai root."; exit 1
    fi
}

install_deps() {
    info "Cek dependency ringan..."
    local need=0
    for pkg in curl wget git jq zip unzip cron at; do
        dpkg -s "$pkg" >/dev/null 2>&1 || need=1
    done
    if [ "$need" = "1" ]; then
        apt update -y >/dev/null 2>&1 || true
        apt install -y curl wget git jq zip unzip cron at >/dev/null 2>&1 || true
    fi
    systemctl enable --now cron >/dev/null 2>&1 || true
    systemctl enable --now atd  >/dev/null 2>&1 || true
}

prepare_repo() {
    info "Update Script dari GitHub..."

    local need_clone=0
    if [ -d "$BASE_DIR/.git" ]; then
        local current
        current=$(git -C "$BASE_DIR" remote get-url origin 2>/dev/null || echo "")
        if [ "$current" != "$REPO_GIT" ]; then
            warn "Remote origin berbeda ($current) — clone ulang ke $REPO_GIT"
            need_clone=1
        fi
    else
        need_clone=1
    fi

    if [ "$need_clone" = "1" ]; then
        rm -rf "$BASE_DIR"
        info "Clone repo dari $REPO_GIT ..."
        git clone "$REPO_GIT" "$BASE_DIR" 2>&1 | tail -3 || { fail "Gagal clone repo"; exit 1; }
    fi

    if ! git -C "$BASE_DIR" fetch origin 2>/dev/null; then
        fail "Gagal fetch dari GitHub. Cek koneksi internet."
        exit 1
    fi
    git -C "$BASE_DIR" reset --hard origin/main >/dev/null 2>&1
    info "Repo berhasil diperbarui ke commit terbaru."

    # shellcheck source=/dev/null
    [ -f "$BASE_DIR/install/install_manifest.sh" ] && source "$BASE_DIR/install/install_manifest.sh"
}

return_menu() {
    echo ""
    info "Proses update selesai."
    sleep 1
    command -v menu >/dev/null 2>&1 && menu
}

main() {
    clear
    need_root
    install_deps
    prepare_repo
    if ! command -v v7_install_manifest >/dev/null 2>&1; then
        fail "install_manifest.sh tidak tersedia."
        exit 1
    fi
    v7_install_manifest "$BASE_DIR" local
    hash -r 2>/dev/null || true
    v7_install_summary
    return_menu
}

main "$@"
