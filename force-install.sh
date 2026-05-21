#!/bin/bash
# ============================================================================
# v7fix — force-install (download semua langsung dari GitHub raw, tanpa git)
# ============================================================================
set +e

REPO_RAW="https://raw.githubusercontent.com/xyzstoree/v7fix/main"

if [ "$(id -u)" != "0" ]; then
    echo "Jalankan sebagai root"; exit 1
fi

apt update -y >/dev/null 2>&1 || true
apt install -y curl jq >/dev/null 2>&1 || true

TMP_INSTALLER=$(mktemp)
curl -fsSL --max-time 15 "${REPO_RAW}/install/install_manifest.sh" -o "$TMP_INSTALLER" 2>/dev/null
if [ ! -s "$TMP_INSTALLER" ]; then
    rm -f "$TMP_INSTALLER"
    echo "[FAIL] Tidak bisa download install_manifest.sh — cek koneksi internet & repo URL."
    exit 1
fi
# shellcheck source=/dev/null
source "$TMP_INSTALLER"
rm -f "$TMP_INSTALLER"

clear
info "v7fix — FORCE INSTALL dari GitHub raw"
echo ""

v7_install_manifest "$REPO_RAW" raw
hash -r 2>/dev/null || true
v7_install_summary

echo ""
sleep 1
command -v menu >/dev/null 2>&1 && menu || true
