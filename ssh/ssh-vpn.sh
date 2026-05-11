#!/bin/bash
# ============================================================================
# SSH / Dropbear / Stunnel / Squid Installer
# AUTOSCRIPT VPS - XYZSTOREE
# ============================================================================

set -e

NC='\e[0m'
green='\e[0;32m'
red='\e[0;31m'
yellow='\e[1;33m'

info() {
    echo -e "[ ${green}INFO${NC} ] $1"
}

warn() {
    echo -e "[ ${yellow}WARN${NC} ] $1"
}

err() {
    echo -e "[ ${red}ERROR${NC} ] $1"
}

if [[ $EUID -ne 0 ]]; then
    err "Script harus dijalankan sebagai root"
    exit 1
fi

REPO=${REPO:-https://raw.githubusercontent.com/xyzstoree/gipalok/main}

clear
info "Installing SSH, Dropbear, Stunnel, Squid"

mkdir -p /var/lib/Anggun
mkdir -p /etc/stunnel
mkdir -p /var/log/squid
mkdir -p /etc/xray
touch /root/log-install.txt

domain="$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || hostname -f 2>/dev/null || curl -sS ifconfig.me 2>/dev/null || echo localhost)"

info "Installing packages"
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
    openssh-server \
    dropbear \
    stunnel4 \
    squid \
    curl \
    wget \
    openssl \
    iptables \
    iptables-persistent \
    netfilter-persistent

# ============================================================================
# OpenSSH Config
# ============================================================================

info "Configuring OpenSSH"

cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s) 2>/dev/null || true

sed -i 's/^#\?Port .*/Port 22/g' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/^#\?UsePAM .*/UsePAM yes/g' /etc/ssh/sshd_config

grep -q '^Port 22' /etc/ssh/sshd_config || echo 'Port 22' >> /etc/ssh/sshd_config
grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# ============================================================================
# HTML Banner via /etc/kyt.txt
# ============================================================================

info "Setting SSH/Dropbear HTML banner"

wget -q -O /etc/kyt.txt "${REPO}/issue.net" || true

if [ ! -s /etc/kyt.txt ]; then
cat > /etc/kyt.txt <<'EOF'
<h6 style="text-align:center;">
<font color="red">▭▬▭▬▭▬▭▬▭▬▭▬▭▬▭▬▭▬▭</font><br><span style="background-color:black;"><font color="#82CAFA"><font face="monospace"><big>WELCOME TO VIP SERVER</big></span><br><font color="magenta">▭▬▭▬▭▬▭▬▭▬▭▬▭▬▭</font><br><font face="monospace"><font color="red"><big>-- SERVER RULESS --</big></font><br><span style="background-color:black;"><font color="">~ No Ddos ~<br>~ No Torrent & Spam ~<br>~ No Hacking & Carding ~<br>~ No Over Download ~<br>~ No Multilogin ~<br>~ No Illegal Activities ~<br><br><font face="monospace"><big><small>卍 PREMIUM BY XYUZZ VPN 卍</span></big></small><br><font color="magenta">▭▬▭▬▭▬▭▬▭▬▭▬▭</font>
EOF
fi

chmod 644 /etc/kyt.txt

sed -i '/^Banner /d' /etc/ssh/sshd_config
sed -i '/^#Banner /d' /etc/ssh/sshd_config
echo "Banner /etc/kyt.txt" >> /etc/ssh/sshd_config

# ============================================================================
# Dropbear Config
# ============================================================================

info "Configuring Dropbear"

cat > /etc/default/dropbear <<'EOF'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -p 110"
DROPBEAR_BANNER="/etc/kyt.txt"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

# ============================================================================
# Stunnel Config
# ============================================================================

info "Configuring Stunnel"

openssl req -new -x509 -days 3650 -nodes \
    -out /etc/stunnel/stunnel.pem \
    -keyout /etc/stunnel/stunnel.pem \
    -subj "/C=ID/ST=Indonesia/L=Indonesia/O=XYZSTOREE/OU=VPN/CN=${domain}" >/dev/null 2>&1 || true

chmod 600 /etc/stunnel/stunnel.pem

cat > /etc/stunnel/stunnel.conf <<'EOF'
cert = /etc/stunnel/stunnel.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear-ssl]
accept = 447
connect = 127.0.0.1:109

[dropbear-ssl2]
accept = 777
connect = 127.0.0.1:143
EOF

cat > /etc/default/stunnel4 <<'EOF'
ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
PPP_RESTART=0
RLIMITS=""
EOF

# ============================================================================
# Squid Config
# ============================================================================

info "Configuring Squid"

cp -a /etc/squid/squid.conf /etc/squid/squid.conf.bak.$(date +%s) 2>/dev/null || true

cat > /etc/squid/squid.conf <<EOF
acl VPN dst ${domain}
acl localhost src 127.0.0.1/32
acl to_localhost dst 127.0.0.0/8
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl Safe_ports port 8080
acl Safe_ports port 8880
acl Safe_ports port 2082
acl Safe_ports port 2086
acl Safe_ports port 2083
acl Safe_ports port 8443
acl CONNECT method CONNECT

http_access allow localhost
http_access allow all
http_port 3128
http_port 8080
visible_hostname ${domain}
EOF

# ============================================================================
# Log Install Info
# ============================================================================

info "Writing log-install.txt"

sed -i '/OpenSSH/d' /root/log-install.txt 2>/dev/null || true
sed -i '/Dropbear/d' /root/log-install.txt 2>/dev/null || true
sed -i '/Stunnel4/d' /root/log-install.txt 2>/dev/null || true
sed -i '/Squid/d' /root/log-install.txt 2>/dev/null || true
sed -i '/SSH Websocket/d' /root/log-install.txt 2>/dev/null || true
sed -i '/SSH SSL Websocket/d' /root/log-install.txt 2>/dev/null || true

cat >> /root/log-install.txt <<EOF
OpenSSH              : 22
Dropbear             : 109, 110, 143
Stunnel4             : 447, 777
Squid                : 3128, 8080
SSH Websocket        : 80, 8080, 8880, 2082, 2086
SSH SSL Websocket    : 443, 8443, 2083
EOF

# ============================================================================
# Firewall
# ============================================================================

info "Opening firewall ports"

for port in 22 80 443 109 110 143 447 777 3128 8080 8880 2082 2083 2086 8443; do
    iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
done

netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# ============================================================================
# Restart Services
# ============================================================================

info "Restarting services"

systemctl daemon-reload

systemctl enable ssh 2>/dev/null || true
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

systemctl enable dropbear 2>/dev/null || true
pkill dropbear 2>/dev/null || true
systemctl restart dropbear 2>/dev/null || /etc/init.d/dropbear restart 2>/dev/null || true

systemctl enable stunnel4 2>/dev/null || true
systemctl restart stunnel4 2>/dev/null || /etc/init.d/stunnel4 restart 2>/dev/null || true

systemctl enable squid 2>/dev/null || true
systemctl restart squid 2>/dev/null || true

info "Checking services"

systemctl status ssh --no-pager -l 2>/dev/null | head -20 || true
systemctl status dropbear --no-pager -l 2>/dev/null | head -20 || true
systemctl status stunnel4 --no-pager -l 2>/dev/null | head -20 || true
systemctl status squid --no-pager -l 2>/dev/null | head -20 || true

echo ""
info "Checking listening ports"
ss -tulpn | grep -E ':22|:109|:110|:143|:447|:777|:3128|:8080|dropbear|stunnel|squid|ssh' || true

echo ""
info "Checking banner"
echo "Banner file: /etc/kyt.txt"
head -c 200 /etc/kyt.txt || true
echo ""

echo ""
info "SSH VPN setup completed"
