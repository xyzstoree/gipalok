#!/bin/bash
# force-install.sh — Download & install semua script langsung dari GitHub raw
# Tidak pakai git, tidak perlu /root/gipalok — 100% fresh dari GitHub
set +e

RAW="https://raw.githubusercontent.com/xyzstoree/gipalok/main"
OK=0; FAIL=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info() { echo -e "${CYAN}[ INFO ]${NC} $1"; }
ok()   { echo -e "${GREEN}[  OK  ]${NC} $1"; }
fail() { echo -e "${RED}[ FAIL ]${NC} $1"; }

if [ "$(id -u)" != "0" ]; then
    echo "Jalankan sebagai root"; exit 1
fi

dl() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if curl -fsSL --max-time 15 "${RAW}/${src}" -o "${dst}.tmp" 2>/dev/null \
       && [ -s "${dst}.tmp" ]; then
        mv "${dst}.tmp" "${dst}"
        chmod +x "$dst" 2>/dev/null || true
        ok "$dst"
        OK=$((OK+1))
    else
        rm -f "${dst}.tmp"
        fail "$src → $dst"
        FAIL=$((FAIL+1))
    fi
}

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "        GIPALOK — FORCE INSTALL"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

info "Download & install semua script ke /usr/bin ..."
echo ""

# MENU UTAMA
dl "Menu/menu.sh"          /usr/local/bin/menu
dl "Menu/menu-ssh.sh"      /usr/local/bin/menu-ssh
dl "Menu/menu-vmess.sh"    /usr/local/bin/menu-vmess
dl "Menu/menu-vless.sh"    /usr/local/bin/menu-vless
dl "Menu/menu-trojan.sh"   /usr/local/bin/menu-trojan
dl "Menu/menu-trgo.sh"     /usr/local/bin/menu-trgo
dl "Menu/menu-set.sh"      /usr/local/bin/menu-set
dl "Menu/menu-bot.sh"      /usr/local/bin/menu-bot
dl "Menu/menu-domain.sh"   /usr/local/bin/menu-domain
dl "Menu/menu-webmin.sh"   /usr/local/bin/menu-webmin
dl "Menu/menu-trial.sh"    /usr/local/bin/menu-trial
dl "Menu/About.sh"         /usr/local/bin/about
dl "Menu/auto-reboot.sh"   /usr/local/bin/auto-reboot
dl "Menu/bw.sh"            /usr/local/bin/bw
dl "Menu/restart.sh"       /usr/local/bin/restart
dl "Menu/running.sh"       /usr/local/bin/running
dl "Menu/clearcache.sh"    /usr/local/bin/clearcache
dl "Menu/clearlog.sh"      /usr/local/bin/clearlog
dl "Menu/mbot.sh"          /usr/local/bin/mbot

# PORT
dl "Port/Port-change.sh"   /usr/local/bin/port-change
dl "Port/port-ssl.sh"      /usr/local/bin/port-ssl
dl "Port/port-ovpn.sh"     /usr/local/bin/port-ovpn
dl "Port/port-tr.sh"       /usr/local/bin/port-tr

# SSH
dl "ssh/usernew.sh"        /usr/local/bin/usernew
dl "ssh/trial.sh"          /usr/local/bin/trial
dl "ssh/renew.sh"          /usr/local/bin/renew
dl "ssh/delete.sh"         /usr/local/bin/delete
dl "ssh/hapus.sh"          /usr/local/bin/hapus
dl "ssh/cek.sh"            /usr/local/bin/cek
dl "ssh/member.sh"         /usr/local/bin/member
dl "ssh/autokill.sh"       /usr/local/bin/autokill
dl "ssh/ceklim.sh"         /usr/local/bin/ceklim
dl "ssh/tendang.sh"        /usr/local/bin/tendang
dl "ssh/add-host.sh"       /usr/local/bin/add-host
dl "ssh/cf.sh"             /usr/local/bin/cf
dl "ssh/genssl.sh"         /usr/local/bin/genssl
dl "ssh/xp.sh"             /usr/local/bin/xp
dl "ssh/user-lock.sh"      /usr/local/bin/user-lock
dl "ssh/user-unlock.sh"    /usr/local/bin/user-unlock
dl "ssh/bbr.sh"            /usr/local/bin/bbr
dl "ssh/speedtest.sh"      /usr/local/bin/speedtest
dl "cf2.sh"                /usr/local/bin/cf2
dl "running.sh"            /usr/local/bin/running2

# XRAY VMESS
dl "xray/add-ws.sh"        /usr/local/bin/add-ws
dl "xray/trialvmess.sh"    /usr/local/bin/trial-ws
dl "xray/renew-ws.sh"      /usr/local/bin/renew-ws
dl "xray/del-ws.sh"        /usr/local/bin/del-ws
dl "xray/cek-ws.sh"        /usr/local/bin/cek-ws

# XRAY VLESS
dl "xray/add-vless.sh"     /usr/local/bin/add-vless
dl "xray/trialvless.sh"    /usr/local/bin/trial-vless
dl "xray/renew-vless.sh"   /usr/local/bin/renew-vless
dl "xray/del-vless.sh"     /usr/local/bin/del-vless
dl "xray/cek-vless.sh"     /usr/local/bin/cek-vless

# XRAY TROJAN
dl "xray/add-tr.sh"        /usr/local/bin/add-tr
dl "xray/trialtrojan.sh"   /usr/local/bin/trial-tr
dl "xray/renew-tr.sh"      /usr/local/bin/renew-tr
dl "xray/del-tr.sh"        /usr/local/bin/del-tr
dl "xray/cek-tr.sh"        /usr/local/bin/cek-tr

# TROJAN GO
dl "xray/addtrgo.sh"       /usr/local/bin/addtrgo
dl "xray/trialtrojango.sh" /usr/local/bin/trialtrojango
dl "xray/renewtrgo.sh"     /usr/local/bin/renewtrgo
dl "xray/deltrgo.sh"       /usr/local/bin/deltrgo
dl "xray/cektrgo.sh"       /usr/local/bin/cektrgo

# BACKUP
dl "Backup/menu-backup.sh"  /usr/local/bin/menu-backup
dl "Backup/set-telegram.sh" /usr/local/bin/set-telegram
dl "Backup/backup.sh"       /usr/local/bin/backup
dl "Backup/restore.sh"      /usr/local/bin/restore
dl "Backup/autobackup.sh"   /usr/local/bin/autobackup
dl "Backup/set-br.sh"       /usr/local/bin/set-br
dl "Backup/strt.sh"         /usr/local/bin/strt
dl "Backup/limitspeed.sh"   /usr/local/bin/limitspeed

# BOT API
dl "api/install-api.sh"     /usr/local/bin/install-api

# QUEUE / LIMIT IP
dl "Queue/Queue-ip-ssh.sh"    /usr/local/bin/limitssh
dl "Queue/Queue-ip-vmess.sh"  /usr/local/bin/limitvmess
dl "Queue/Queue-ip-vless.sh"  /usr/local/bin/limitvless
dl "Queue/Queue-ip-trojan.sh" /usr/local/bin/limittrojan

# QUEUE / QUOTA
dl "Queue/quota-vmess-ws.sh"        /usr/local/bin/quota-vmess-ws
dl "Queue/quota-vless-ws.sh"        /usr/local/bin/quota-vless-ws
dl "Queue/quota-trojan-ws.sh"       /usr/local/bin/quota-trojan-ws
dl "Queue/quota-vmess-grpc.sh"      /usr/local/bin/quota-vmess-grpc
dl "Queue/quota-trojan-grpc.sh"     /usr/local/bin/quota-trojan-grpc
dl "Queue/quota-vmess-ws-orbit.sh"  /usr/local/bin/quota-vmess-ws-orbit
dl "Queue/quota-vmess-ws-orbit1.sh" /usr/local/bin/quota-vmess-ws-orbit1
dl "Queue/Queue-quota-vmess.sh"     /usr/local/bin/Queue-quota-vmess
dl "Queue/Queue-quota-vless.sh"     /usr/local/bin/Queue-quota-vless
dl "Queue/quota.sh"                 /usr/local/bin/quota
dl "Queue/Queue.sh"                 /usr/local/bin/Queue
dl "Queue/loop.sh"                  /usr/local/bin/loop
dl "Queue/matikan.sh"               /usr/local/bin/matikan
dl "Queue/cek-ssh.sh"               /usr/local/bin/cek-ssh
dl "Queue/mesinssh.sh"              /usr/local/bin/mesinssh
dl "Queue/nskk.sh"                  /usr/local/bin/nskk

# UPDATE SELF
dl "updatemenu.sh"          /usr/local/bin/updatemenu
dl "force-install.sh"       /usr/local/bin/force-install

# Buat alias dash agar command lama tetap jalan
for pair in "limitssh:limit-ssh" "limitvmess:limit-vmess" "limitvless:limit-vless" "limittrojan:limit-trojan"; do
    src="${pair%%:*}"; dst="${pair##*:}"
    cp /usr/local/bin/$src /usr/local/bin/$dst 2>/dev/null && chmod +x /usr/local/bin/$dst || true
done

# Sinkron juga ke /root/gipalok/ supaya path lama tidak ketinggalan
if [ -d "/root/gipalok" ]; then
    info "Sinkron juga ke /root/gipalok/ ..."
    for f in /usr/local/bin/menu /usr/local/bin/running /usr/local/bin/renew /usr/local/bin/add-ws \
              /usr/local/bin/add-vless /usr/local/bin/add-tr /usr/local/bin/addtrgo \
              /usr/local/bin/quota-vmess-ws /usr/local/bin/quota-vless-ws \
              /usr/local/bin/quota-trojan-ws /usr/local/bin/quota-vmess-grpc \
              /usr/local/bin/limitssh /usr/local/bin/limitvmess /usr/local/bin/limitvless /usr/local/bin/limittrojan \
              /usr/local/bin/Queue-quota-vmess /usr/local/bin/Queue-quota-vless; do
        [ -f "$f" ] && cp "$f" /root/gipalok/ 2>/dev/null || true
    done
fi

# Reset shell command cache
hash -r 2>/dev/null || true

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  SELESAI — ${GREEN}OK: $OK${NC}  |  ${RED}FAIL: $FAIL${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
[ $FAIL -gt 0 ] && echo -e "${YELLOW}Cek koneksi internet VPS jika ada FAIL.${NC}" && echo ""
sleep 2
command -v menu >/dev/null 2>&1 && menu || true
