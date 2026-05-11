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
dl "Menu/menu.sh"          /usr/bin/menu
dl "Menu/menu-ssh.sh"      /usr/bin/menu-ssh
dl "Menu/menu-vmess.sh"    /usr/bin/menu-vmess
dl "Menu/menu-vless.sh"    /usr/bin/menu-vless
dl "Menu/menu-trojan.sh"   /usr/bin/menu-trojan
dl "Menu/menu-trgo.sh"     /usr/bin/menu-trgo
dl "Menu/menu-set.sh"      /usr/bin/menu-set
dl "Menu/menu-bot.sh"      /usr/bin/menu-bot
dl "Menu/menu-domain.sh"   /usr/bin/menu-domain
dl "Menu/menu-webmin.sh"   /usr/bin/menu-webmin
dl "Menu/menu-trial.sh"    /usr/bin/menu-trial
dl "Menu/About.sh"         /usr/bin/about
dl "Menu/auto-reboot.sh"   /usr/bin/auto-reboot
dl "Menu/bw.sh"            /usr/bin/bw
dl "Menu/restart.sh"       /usr/bin/restart
dl "Menu/running.sh"       /usr/bin/running
dl "Menu/clearcache.sh"    /usr/bin/clearcache
dl "Menu/clearlog.sh"      /usr/bin/clearlog
dl "Menu/mbot.sh"          /usr/bin/mbot

# PORT
dl "Port/Port-change.sh"   /usr/bin/port-change
dl "Port/port-ssl.sh"      /usr/bin/port-ssl
dl "Port/port-ovpn.sh"     /usr/bin/port-ovpn
dl "Port/port-tr.sh"       /usr/bin/port-tr

# SSH
dl "ssh/usernew.sh"        /usr/bin/usernew
dl "ssh/trial.sh"          /usr/bin/trial
dl "ssh/renew.sh"          /usr/bin/renew
dl "ssh/delete.sh"         /usr/bin/delete
dl "ssh/hapus.sh"          /usr/bin/hapus
dl "ssh/cek.sh"            /usr/bin/cek
dl "ssh/member.sh"         /usr/bin/member
dl "ssh/autokill.sh"       /usr/bin/autokill
dl "ssh/ceklim.sh"         /usr/bin/ceklim
dl "ssh/tendang.sh"        /usr/bin/tendang
dl "ssh/add-host.sh"       /usr/bin/add-host
dl "ssh/cf.sh"             /usr/bin/cf
dl "ssh/genssl.sh"         /usr/bin/genssl
dl "ssh/xp.sh"             /usr/bin/xp
dl "ssh/user-lock.sh"      /usr/bin/user-lock
dl "ssh/user-unlock.sh"    /usr/bin/user-unlock
dl "ssh/bbr.sh"            /usr/bin/bbr
dl "ssh/speedtest.sh"      /usr/bin/speedtest
dl "cf2.sh"                /usr/bin/cf2
dl "running.sh"            /usr/bin/running2

# XRAY VMESS
dl "xray/add-ws.sh"        /usr/bin/add-ws
dl "xray/trialvmess.sh"    /usr/bin/trial-ws
dl "xray/renew-ws.sh"      /usr/bin/renew-ws
dl "xray/del-ws.sh"        /usr/bin/del-ws
dl "xray/cek-ws.sh"        /usr/bin/cek-ws

# XRAY VLESS
dl "xray/add-vless.sh"     /usr/bin/add-vless
dl "xray/trialvless.sh"    /usr/bin/trial-vless
dl "xray/renew-vless.sh"   /usr/bin/renew-vless
dl "xray/del-vless.sh"     /usr/bin/del-vless
dl "xray/cek-vless.sh"     /usr/bin/cek-vless

# XRAY TROJAN
dl "xray/add-tr.sh"        /usr/bin/add-tr
dl "xray/trialtrojan.sh"   /usr/bin/trial-tr
dl "xray/renew-tr.sh"      /usr/bin/renew-tr
dl "xray/del-tr.sh"        /usr/bin/del-tr
dl "xray/cek-tr.sh"        /usr/bin/cek-tr

# TROJAN GO
dl "xray/addtrgo.sh"       /usr/bin/addtrgo
dl "xray/trialtrojango.sh" /usr/bin/trialtrojango
dl "xray/renewtrgo.sh"     /usr/bin/renewtrgo
dl "xray/deltrgo.sh"       /usr/bin/deltrgo
dl "xray/cektrgo.sh"       /usr/bin/cektrgo

# BACKUP
dl "Backup/menu-backup.sh"  /usr/bin/menu-backup
dl "Backup/set-telegram.sh" /usr/bin/set-telegram
dl "Backup/backup.sh"       /usr/bin/backup
dl "Backup/restore.sh"      /usr/bin/restore
dl "Backup/autobackup.sh"   /usr/bin/autobackup
dl "Backup/set-br.sh"       /usr/bin/set-br
dl "Backup/strt.sh"         /usr/bin/strt
dl "Backup/limitspeed.sh"   /usr/bin/limitspeed

# BOT API
dl "api/install-api.sh"     /usr/bin/install-api

# QUEUE / LIMIT IP
dl "Queue/Queue-ip-ssh.sh"    /usr/bin/limitssh
dl "Queue/Queue-ip-vmess.sh"  /usr/bin/limitvmess
dl "Queue/Queue-ip-vless.sh"  /usr/bin/limitvless
dl "Queue/Queue-ip-trojan.sh" /usr/bin/limittrojan

# QUEUE / QUOTA
dl "Queue/quota-vmess-ws.sh"        /usr/bin/quota-vmess-ws
dl "Queue/quota-vless-ws.sh"        /usr/bin/quota-vless-ws
dl "Queue/quota-trojan-ws.sh"       /usr/bin/quota-trojan-ws
dl "Queue/quota-vmess-grpc.sh"      /usr/bin/quota-vmess-grpc
dl "Queue/quota-trojan-grpc.sh"     /usr/bin/quota-trojan-grpc
dl "Queue/quota-vmess-ws-orbit.sh"  /usr/bin/quota-vmess-ws-orbit
dl "Queue/quota-vmess-ws-orbit1.sh" /usr/bin/quota-vmess-ws-orbit1
dl "Queue/Queue-quota-vmess.sh"     /usr/bin/Queue-quota-vmess
dl "Queue/Queue-quota-vless.sh"     /usr/bin/Queue-quota-vless
dl "Queue/quota.sh"                 /usr/bin/quota
dl "Queue/Queue.sh"                 /usr/bin/Queue
dl "Queue/loop.sh"                  /usr/bin/loop
dl "Queue/matikan.sh"               /usr/bin/matikan
dl "Queue/cek-ssh.sh"               /usr/bin/cek-ssh
dl "Queue/mesinssh.sh"              /usr/bin/mesinssh
dl "Queue/nskk.sh"                  /usr/bin/nskk

# UPDATE SELF
dl "updatemenu.sh"          /usr/bin/updatemenu
dl "force-install.sh"       /usr/bin/force-install

# Buat alias dash agar command lama tetap jalan
for pair in "limitssh:limit-ssh" "limitvmess:limit-vmess" "limitvless:limit-vless" "limittrojan:limit-trojan"; do
    src="${pair%%:*}"; dst="${pair##*:}"
    cp /usr/bin/$src /usr/bin/$dst 2>/dev/null && chmod +x /usr/bin/$dst || true
done

# Sinkron juga ke /root/gipalok/ supaya path lama tidak ketinggalan
if [ -d "/root/gipalok" ]; then
    info "Sinkron juga ke /root/gipalok/ ..."
    for f in /usr/bin/menu /usr/bin/running /usr/bin/renew /usr/bin/add-ws \
              /usr/bin/add-vless /usr/bin/add-tr /usr/bin/addtrgo \
              /usr/bin/quota-vmess-ws /usr/bin/quota-vless-ws \
              /usr/bin/quota-trojan-ws /usr/bin/quota-vmess-grpc \
              /usr/bin/limitssh /usr/bin/limitvmess /usr/bin/limitvless /usr/bin/limittrojan \
              /usr/bin/Queue-quota-vmess /usr/bin/Queue-quota-vless; do
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
