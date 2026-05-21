#!/bin/bash
set -e
# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

mkdir -p /var/lib/Anggun /etc/Anggun/Queue/trojan/quota /etc/Anggun/Queue/trojan/ip
touch /root/log-install.txt

source /var/lib/Anggun/ipvps.conf 2>/dev/null || true
if [[ -z "${IP:-}" ]]; then
  domain=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || curl -sS --max-time 5 ifconfig.me)
else
  domain=$IP
fi

tr="$(grep -w "Trojan WS" ~/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"
[ -z "$tr" ] && tr="443"

xray_api_add_trojan() {
  local tag="$1" port="$2" network="$3" user="$4" pass="$5" tmp
  tmp=$(mktemp)
  cat > "$tmp" <<EOFAPI
{
  "inbounds": [
    {
      "tag": "$tag",
      "listen": "127.0.0.1",
      "port": $port,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "$pass", "email": "$user" }
        ]
      },
      "streamSettings": { "network": "$network" }
    }
  ]
}
EOFAPI
  # FIX: 'xray api adu' → 'xray api addinbound' (adu is not a valid command)
  /usr/local/bin/xray api addinbound --server=127.0.0.1:10085 -c "$tmp" 2>/dev/null
  local code=$?
  rm -f "$tmp"
  return $code
}

clear
until [[ ${user:-} =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS:-0} == '0' ]]; do
  echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo -e "\E[0;41;36m TROJAN ACCOUNT \E[0m"
  echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  read -rp "User: " -e user
  if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "Username hanya boleh huruf, angka, dan underscore."
    CLIENT_EXISTS=1; continue
  fi
  CLIENT_EXISTS=$(jq --arg user "$user" '[.. | objects | select(has("email")) | select(.email == $user)] | length' /etc/xray/config.json 2>/dev/null || echo 0)
  if [[ ${CLIENT_EXISTS} != '0' ]]; then
    echo "User '$user' sudah ada, pilih nama lain."
    CLIENT_EXISTS=1; user=""
  fi
done

uuid=$(cat /proc/sys/kernel/random/uuid)
read -p "Expired (days): " masaaktif
read -p "Limit (GB) [0=unlimited]: " quota
read -p "Max Login IP [0=unlimited]: " ipQueue
[ -z "$masaaktif" ] && masaaktif=30
[ -z "$quota" ]     && quota=0
[ -z "$ipQueue" ]   && ipQueue=0

if ! echo "$masaaktif" | grep -Eq '^[0-9]+$'; then masaaktif=30; fi
if ! echo "$quota"     | grep -Eq '^[0-9]+$'; then quota=0;      fi
if ! echo "$ipQueue"   | grep -Eq '^[0-9]+$'; then ipQueue=0;    fi

[[ $quota   -gt 0 ]] && echo "$((quota * 1024 * 1024 * 1024))" > /etc/Anggun/Queue/trojan/quota/$user
[[ $ipQueue -gt 0 ]] && echo "$ipQueue" > /etc/Anggun/Queue/trojan/ip/$user

# FIX: date -d "+$masaaktif days" (original was missing + prefix)
exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")
mkdir -p /etc/Anggun/Expiry/trojan
echo "$exp" > /etc/Anggun/Expiry/trojan/$user

backup="/etc/xray/config.json.bak.$(date +%s)"
cp /etc/xray/config.json "$backup"
tmp=$(mktemp)

jq --arg user "$user" --arg exp "$exp" --arg uuid "$uuid" '
  .inbounds |= map(
    if (.tag == "trojan-ws" or .tag == "trojan-grpc") then
      .settings.clients += [{"password": $uuid, "email": $user}]
    else . end
  )
  | ._metadata = (._metadata // {})
  | ._metadata.trojan = (._metadata.trojan // {})
  | ._metadata.trojan[$user] = {"user": $user, "uuid": $uuid, "exp": $exp}
' /etc/xray/config.json > "$tmp"

if ! jq . "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    echo "[ERROR] JSON config tidak valid, akun batal dibuat."
    sleep 3; menu 2>/dev/null || true; exit 1
fi
mv "$tmp" /etc/xray/config.json

if xray_api_add_trojan "trojan-ws" 10003 "ws" "$user" "$uuid" && \
   xray_api_add_trojan "trojan-grpc" 10007 "grpc" "$user" "$uuid"; then
  echo "[OK] User ditambahkan live via Xray API (tidak perlu restart)"
else
  echo "[INFO] Xray API tidak tersedia, fallback restart xray..."
  systemctl restart xray.service 2>/dev/null || true
fi

trojanlink="trojan://${uuid}@${domain}:443?path=%2Ftrojan-ws&security=tls&host=${domain}&type=ws&sni=${domain}#${user}"
trojanlink2="trojan://${uuid}@${domain}:80?path=%2Ftrojan-ws&security=none&host=${domain}&type=ws#${user}"
trojanlink3="trojan://${uuid}@${domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${domain}#${user}"

clear
{
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "\E[0;41;36m Trojan Account \E[0m"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Remarks       : ${user}"
echo -e "Host/IP       : ${domain}"
echo -e "Port WS TLS   : 443"
echo -e "Port WS NTLS  : 80, 8080, 8880, 2082, 2086"
echo -e "Port GRPC     : 443"
echo -e "Key           : ${uuid}"
echo -e "Path          : /trojan-ws"
echo -e "ServiceName   : trojan-grpc"
echo -e "Quota         : ${quota} GB"
echo -e "Max Login     : ${ipQueue} IP"
echo -e "Link WS TLS   : ${trojanlink}"
echo -e "Link WS NTLS  : ${trojanlink2}"
echo -e "Link GRPC     : ${trojanlink3}"
echo -e "Expired On    : $exp"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━◇\033[0m"
} | tee -a /etc/log-create-user.log
read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
menu
