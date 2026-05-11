#!/bin/bash
clear
red='\e[1;31m'
green2='\e[1;32m'
yell='\e[1;33m'
NC='\e[0m'
green()  { echo -e "\\033[32;1m${*}\\033[0m"; }
red()    { echo -e "\\033[31;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }

echo "           Tools install...!"
echo "                  Progress..."
sleep 0.5

NET=$(ip route | grep default | awk '{print $5}' | head -n1)
[ -z "$NET" ] && NET="eth0"
echo "[INFO] Network Interface: $NET"

echo "[*] Updating system packages..."
apt update -y
apt upgrade -y
apt install -y sudo

echo "[*] Removing unnecessary packages..."
sudo apt-get clean all
sudo apt-get install -y debconf-utils
apt-get remove --purge ufw firewalld -y 2>/dev/null || true
apt-get remove --purge exim4 -y 2>/dev/null || true
apt-get autoremove -y

sudo apt-get install -y --no-install-recommends software-properties-common

echo "[*] Configuring iptables..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

echo "[*] Installing core packages..."
# FIX: Removed 'python' (Python 2 is EOL and unavailable on Ubuntu 22+, causes apt failure)
# FIX: Removed 'speedtest-cli' (conflicts with newer speedtest packages on some distros)
sudo apt-get install -y iptables iptables-persistent netfilter-persistent figlet ruby \
    php php-fpm php-cli php-mysql libxml-parser-perl squid nmap screen curl jq \
    bzip2 gzip coreutils rsyslog iftop libjpeg-dev zlib1g-dev python3 \
    python3-pip shc build-essential p7zip-full nodejs nginx

echo "[*] Ensuring nginx is properly installed..."
apt install -y nginx

echo "[*] Cleaning up unnecessary packages..."
sudo apt-get autoclean -y >/dev/null 2>&1 || true
sudo apt-get -y --purge remove unscd  >/dev/null 2>&1 || true
sudo apt-get -y --purge remove samba* >/dev/null 2>&1 || true
sudo apt-get -y --purge remove apache2* >/dev/null 2>&1 || true
sudo apt-get -y --purge remove bind9* >/dev/null 2>&1 || true
sudo apt-get -y remove sendmail* >/dev/null 2>&1 || true
apt autoremove -y >/dev/null 2>&1 || true

echo "[*] Installing and configuring vnstat..."
sudo apt-get -y install vnstat
/etc/init.d/vnstat restart 2>/dev/null || true
apt -y install libsqlite3-dev

echo "[*] Downloading vnstat 2.6..."
cd /tmp || exit
wget -q https://humdi.net/vnstat/vnstat-2.6.tar.gz
if [ -f "vnstat-2.6.tar.gz" ]; then
    tar zxvf vnstat-2.6.tar.gz
    cd vnstat-2.6 || exit
    ./configure --prefix=/usr --sysconfdir=/etc && make && make install
    cd /tmp || exit
    vnstat -u -i "$NET"
    sed -i "s/Interface \"eth0\"/Interface \"$NET\"/g" /etc/vnstat.conf
    chown vnstat:vnstat /var/lib/vnstat -R
    systemctl enable vnstat
    /etc/init.d/vnstat restart
    rm -f /tmp/vnstat-2.6.tar.gz
    rm -rf /tmp/vnstat-2.6
else
    echo "[WARN] vnstat download failed, skipping vnstat build"
fi

cd /root || exit

echo ""
yellow "✓ Dependencies successfully installed..."
echo ""
sleep 1
clear
