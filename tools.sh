#!/bin/bash
# ============================================================================
# v7fix — base dependency installer
# Removed vs gipalok:
#   - php / php-fpm / php-cli / php-mysql  (no script uses PHP)
#   - squid                                (no script uses Squid)
#   - nmap                                 (security audit footprint, unused)
#   - speedtest-cli (apt)                  (conflicts with newer ookla cli)
#   - vnstat 2.6 manual build (humdi.net)  (apt vnstat is enough for --oneline)
#   - python (Python 2 EOL, fails on 22+)
#   - libxml-parser-perl, libjpeg-dev, zlib1g-dev (unused by any script)
# ============================================================================

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

clear
echo "      v7fix — Tools install"
echo "      ====================="

NET=$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')
[ -z "$NET" ] && NET="eth0"
info "Network Interface terdeteksi: $NET"

info "Update apt index..."
apt update -y >/dev/null 2>&1 || true

info "Hapus paket yang tidak dipakai..."
apt-get remove --purge -y ufw firewalld exim4 sendmail* unscd \
    samba* apache2* bind9* 2>/dev/null || true
apt-get autoremove -y >/dev/null 2>&1 || true

info "Konfigurasi iptables-persistent (auto-save yes)..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

info "Install paket yang dibutuhkan..."
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sudo curl wget git jq screen nano cron at \
    iptables iptables-persistent netfilter-persistent \
    figlet ruby \
    unzip zip bzip2 gzip p7zip-full coreutils rsyslog iftop \
    python3 python3-pip uuid-runtime \
    nginx vnstat \
    build-essential || warn "Beberapa paket gagal install — cek log apt."

# lolcat (best-effort)
gem install --no-document lolcat >/dev/null 2>&1 || apt-get install -y lolcat >/dev/null 2>&1 || true

info "Konfigurasi vnstat..."
vnstat -u -i "$NET" >/dev/null 2>&1 || true
sed -i "s/^Interface[[:space:]]\+\".*\"/Interface \"$NET\"/g" /etc/vnstat.conf 2>/dev/null || true
chown vnstat:vnstat /var/lib/vnstat -R 2>/dev/null || true
systemctl enable vnstat >/dev/null 2>&1 || true
systemctl restart vnstat >/dev/null 2>&1 || true

info "Aktifkan service dasar..."
systemctl enable --now cron >/dev/null 2>&1 || true
systemctl enable --now atd  >/dev/null 2>&1 || true

ok "Dependencies selesai diinstall."
sleep 1
clear
