#!/bin/bash
set -e

NC='\e[0m'
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'

info(){ echo -e "[ ${GREEN}INFO${NC} ] $1"; }
warn(){ echo -e "[ ${YELLOW}WARN${NC} ] $1"; }
err(){ echo -e "[ ${RED}ERROR${NC} ] $1"; }

if [ "$(id -u)" != "0" ]; then
  err "Script harus dijalankan sebagai root"
  exit 1
fi

clear
info "Installing / repairing Xray, NGINX TLS 443, Dropbear, and SSH WebSocket"

# Domain source fallback
if [ -n "${IP:-}" ]; then
  domain="$IP"
elif [ -s /root/domain ]; then
  domain=$(cat /root/domain)
elif [ -s /etc/xray/domain ]; then
  domain=$(cat /etc/xray/domain)
else
  read -rp "Masukkan domain/subdomain VPS: " domain
  mkdir -p /etc/xray
  echo "$domain" > /root/domain
  echo "$domain" > /etc/xray/domain
fi

mkdir -p /etc/xray /var/log/xray /run/xray /etc/nginx/conf.d /etc/trojan-go /var/log/trojan-go /var/www/html

echo "$domain" > /etc/xray/domain

touch /var/log/xray/access.log /var/log/xray/error.log
chown -R root:root /var/log/xray /run/xray
chmod 755 /var/log/xray /run/xray
chmod 644 /var/log/xray/access.log /var/log/xray/error.log

touch /var/log/trojan-go/trojan-go.log

info "Installing dependencies"
apt update
apt install -y curl wget unzip jq nginx certbot openssl iptables iptables-persistent dropbear stunnel4 socat net-tools cron python2 || true

info "Installing Xray core"
if [ ! -x /usr/local/bin/xray ]; then
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
else
  warn "Xray binary already exists, skipping core install"
fi

info "Preparing SSL certificate"
CERT_DIR="/etc/letsencrypt/live/${domain}"
CERT_FILE="${CERT_DIR}/fullchain.pem"
KEY_FILE="${CERT_DIR}/privkey.pem"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  systemctl stop nginx 2>/dev/null || true
  certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --register-unsafely-without-email \
    -d "$domain" || {
      warn "Certbot gagal. Membuat self-signed certificate sementara."
      mkdir -p "$CERT_DIR"
      openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/CN=$domain"
    }
fi

uuid=$(cat /proc/sys/kernel/random/uuid)

info "Configuring Dropbear"
wget -q -O /etc/kyt.txt "https://raw.githubusercontent.com/xyzstoree/v7fix/main/issue.net" || true
[ -s /etc/kyt.txt ] || echo "WELCOME TO VIP SERVER" > /etc/kyt.txt
chmod 644 /etc/kyt.txt

cat > /etc/default/dropbear <<'DROPBEAR_EOF'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -p 110 -b /etc/kyt.txt"
DROPBEAR_BANNER="/etc/kyt.txt"
DROPBEAR_RECEIVE_WINDOW=65536
DROPBEAR_EOF

systemctl enable dropbear >/dev/null 2>&1 || true
systemctl restart dropbear || true

info "Writing Xray config with API HandlerService"
cat > /etc/xray/config.json <<EOFJSON
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "api",
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1",
        "rewriteAddress": "127.0.0.1"
      }
    },
    {
      "tag": "vless-ws",
      "listen": "127.0.0.1",
      "port": 10001,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          { "id": "${uuid}", "email": "default-vless-ws" }
        ]
      },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } }
    },
    {
      "tag": "vmess-ws",
      "listen": "127.0.0.1",
      "port": 10002,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "${uuid}", "alterId": 0, "email": "default-vmess-ws" }
        ]
      },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
    },
    {
      "tag": "trojan-ws",
      "listen": "127.0.0.1",
      "port": 10003,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "${uuid}", "email": "default-trojan-ws" }
        ],
        "udp": true
      },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan-ws" } }
    },
    {
      "tag": "ss-ws",
      "listen": "127.0.0.1",
      "port": 10004,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-128-gcm",
        "password": "${uuid}",
        "network": "tcp,udp"
      },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/ss-ws" } }
    },
    {
      "tag": "vless-grpc",
      "listen": "127.0.0.1",
      "port": 10005,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          { "id": "${uuid}", "email": "default-vless-grpc" }
        ]
      },
      "streamSettings": { "network": "grpc", "grpcSettings": { "serviceName": "vless-grpc" } }
    },
    {
      "tag": "vmess-grpc",
      "listen": "127.0.0.1",
      "port": 10006,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "${uuid}", "alterId": 0, "email": "default-vmess-grpc" }
        ]
      },
      "streamSettings": { "network": "grpc", "grpcSettings": { "serviceName": "vmess-grpc" } }
    },
    {
      "tag": "trojan-grpc",
      "listen": "127.0.0.1",
      "port": 10007,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "${uuid}", "email": "default-trojan-grpc" }
        ]
      },
      "streamSettings": { "network": "grpc", "grpcSettings": { "serviceName": "trojan-grpc" } }
    },
    {
      "tag": "ss-grpc",
      "listen": "127.0.0.1",
      "port": 10008,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-128-gcm",
        "password": "${uuid}",
        "network": "tcp,udp"
      },
      "streamSettings": { "network": "grpc", "grpcSettings": { "serviceName": "ss-grpc" } }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": {} },
    { "protocol": "blackhole", "settings": {}, "tag": "blocked" }
  ],
  "routing": {
    "rules": [
      { "type": "field", "inboundTag": ["api"], "outboundTag": "api" },
      { "type": "field", "outboundTag": "blocked", "protocol": ["bittorrent"] }
    ]
  },
  "stats": {},
  "api": {
    "services": ["HandlerService", "StatsService"],
    "tag": "api"
  },
  "policy": {
    "levels": { "0": { "statsUserDownlink": true, "statsUserUplink": true } },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  },
  "_metadata": {
    "vmess": {},
    "vless": {},
    "trojan": {}
  }
}
EOFJSON

info "Writing Xray systemd service"
cat > /etc/systemd/system/xray.service <<'XRAY_SERVICE'
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
NoNewPrivileges=false
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
XRAY_SERVICE

info "Writing NGINX config with HTTP and TLS ports"
rm -f /etc/nginx/conf.d/ssh-ws.conf /etc/nginx/conf.d/xray-vpn.conf 2>/dev/null || true
cat > /etc/nginx/conf.d/xray-vpn.conf <<EOFNGINX
server {
    listen 80;
    listen 8080;
    listen 8880;
    listen 2082;
    listen 2086;

    server_name ${domain};

    client_max_body_size 0;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;

    location / {
        proxy_pass http://127.0.0.1:10015;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /vless {
        proxy_pass http://127.0.0.1:10001;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /vmess {
        proxy_pass http://127.0.0.1:10002;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /trojan-ws {
        proxy_pass http://127.0.0.1:10003;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /ss-ws {
        proxy_pass http://127.0.0.1:10004;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}

server {
    listen 443 ssl;
    listen 8443 ssl;
    listen 2083 ssl;

    server_name ${domain};

    ssl_certificate ${CERT_FILE};
    ssl_certificate_key ${KEY_FILE};
    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 0;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;

    location / {
        proxy_pass http://127.0.0.1:10015;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /vless {
        proxy_pass http://127.0.0.1:10001;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /vmess {
        proxy_pass http://127.0.0.1:10002;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /trojan-ws {
        proxy_pass http://127.0.0.1:10003;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /ss-ws {
        proxy_pass http://127.0.0.1:10004;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /vless-grpc { grpc_pass grpc://127.0.0.1:10005; }
    location /vmess-grpc { grpc_pass grpc://127.0.0.1:10006; }
    location /trojan-grpc { grpc_pass grpc://127.0.0.1:10007; }
    location /ss-grpc { grpc_pass grpc://127.0.0.1:10008; }
}
EOFNGINX

rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

info "Validating config"
jq . /etc/xray/config.json >/dev/null
/usr/local/bin/xray run -test -config /etc/xray/config.json
nginx -t

info "Installing SSH WebSocket"
if [ -f ./sshws/insshws.sh ]; then
  chmod +x ./sshws/insshws.sh
  bash ./sshws/insshws.sh
elif [ -f /root/v7fix/sshws/insshws.sh ]; then
  chmod +x /root/v7fix/sshws/insshws.sh
  bash /root/v7fix/sshws/insshws.sh
else
  warn "sshws/insshws.sh tidak ditemukan, skip SSH WebSocket"
fi

info "Restarting services"
systemctl daemon-reload
systemctl enable xray nginx dropbear >/dev/null 2>&1 || true

systemctl restart xray
systemctl restart nginx
systemctl restart dropbear || true
systemctl restart ws || true

info "Done"
systemctl status xray nginx dropbear ws --no-pager -l || true
