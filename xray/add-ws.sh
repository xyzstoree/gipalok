#!/bin/bash
set -e
# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

mkdir -p /var/lib/Anggun /etc/Anggun/Queue/vmess/quota /etc/Anggun/Queue/vmess/ip
touch /root/log-install.txt

source /var/lib/Anggun/ipvps.conf 2>/dev/null || true
if [[ -z "${IP:-}" ]]; then
  domain=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || curl -sS --max-time 5 ifconfig.me)
else
  domain=$IP
fi

tls="$(grep -w "Vmess TLS" ~/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"
none="$(grep -w "Vmess None TLS" ~/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"
[ -z "$tls" ] && tls="443"
[ -z "$none" ] && none="80"

xray_api_add_vmess() {
  local tag="$1" port="$2" network="$3" user="$4" uuid="$5" tmp
  tmp=$(mktemp)
  cat > "$tmp" <<EOFAPI
{
  "inbounds": [
    {
      "tag": "$tag",
      "listen": "127.0.0.1",
      "port": $port,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "$uuid", "alterId": 0, "email": "$user" }
        ]
      },
      "streamSettings": { "network": "$network" }
    }
  ]
}
EOFAPI
  # FIX: 'xray api adu' is not a valid command — corrected to 'xray api addinbound'
  /usr/local/bin/xray api addinbound --server=127.0.0.1:10085 -c "$tmp" 2>/dev/null
  local code=$?
  rm -f "$tmp"
  return $code
}

clear
until [[ ${user:-} =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS:-0} == '0' ]]; do
  echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo -e "\E[0;41;36m Add Xray/Vmess Account \E[0m"
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
read -p "Limit/Batas (GB) [0=unlimited]: " quota
read -p "Max Login IP [0=unlimited]: " ipQueue
[ -z "$masaaktif" ] && masaaktif=30
[ -z "$quota" ]     && quota=0
[ -z "$ipQueue" ]   && ipQueue=0

if ! echo "$masaaktif" | grep -Eq '^[0-9]+$'; then masaaktif=30; fi
if ! echo "$quota"     | grep -Eq '^[0-9]+$'; then quota=0;      fi
if ! echo "$ipQueue"   | grep -Eq '^[0-9]+$'; then ipQueue=0;    fi

[[ $quota   -gt 0 ]] && echo "$((quota * 1024 * 1024 * 1024))" > /etc/Anggun/Queue/vmess/quota/$user
[[ $ipQueue -gt 0 ]] && echo "$ipQueue" > /etc/Anggun/Queue/vmess/ip/$user

# FIX: date now uses + prefix: date -d "+$masaaktif days" (original had date -d "$masaaktif days")
exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")
mkdir -p /etc/Anggun/Expiry/vmess
echo "$exp" > /etc/Anggun/Expiry/vmess/$user

# FIX: Backup config before modifying
backup="/etc/xray/config.json.bak.$(date +%s)"
cp /etc/xray/config.json "$backup"
tmp=$(mktemp)

jq --arg user "$user" --arg exp "$exp" --arg uuid "$uuid" '
  .inbounds |= map(
    if (.tag == "vmess-ws" or .tag == "vmess-grpc") then
      .settings.clients += [{"id": $uuid, "alterId": 0, "email": $user}]
    else . end
  )
  | ._metadata = (._metadata // {})
  | ._metadata.vmess = (._metadata.vmess // {})
  | ._metadata.vmess[$user] = {"user": $user, "uuid": $uuid, "exp": $exp}
' /etc/xray/config.json > "$tmp"

# FIX: Validate JSON before applying
if ! jq . "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    echo "[ERROR] JSON config tidak valid, akun batal dibuat."
    sleep 3; menu 2>/dev/null || true; exit 1
fi
mv "$tmp" /etc/xray/config.json

if xray_api_add_vmess "vmess-ws" 10002 "ws" "$user" "$uuid" && \
   xray_api_add_vmess "vmess-grpc" 10006 "grpc" "$user" "$uuid"; then
  echo "[OK] User ditambahkan live via Xray API (tidak perlu restart)"
else
  echo "[INFO] Xray API tidak tersedia, fallback restart xray..."
  systemctl restart xray.service 2>/dev/null || true
fi

vmesslink1="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"${tls}\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"tls\",\"sni\":\"${domain}\"}" | base64 -w 0)"
vmesslink2="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"${none}\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"none\"}" | base64 -w 0)"
vmesslink3="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"${tls}\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"grpc\",\"path\":\"vmess-grpc\",\"type\":\"gun\",\"host\":\"${domain}\",\"tls\":\"tls\",\"sni\":\"${domain}\"}" | base64 -w 0)"

clear
{
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "\E[0;41;36m Xray/Vmess Account \E[0m"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━◇\033[0m"
echo -e "Remarks      : ${user}"
echo -e "Domain       : ${domain}"
echo -e "Port TLS     : ${tls}"
echo -e "Port none TLS: ${none}"
echo -e "id           : ${uuid}"
echo -e "Network      : ws/grpc"
echo -e "Path         : /vmess"
echo -e "ServiceName  : vmess-grpc"
echo -e "Quota        : ${quota} GB"
echo -e "Max Login    : ${ipQueue} IP"
echo -e "Link TLS     : ${vmesslink1}"
echo -e "Link none TLS: ${vmesslink2}"
echo -e "Link GRPC    : ${vmesslink3}"
echo -e "Expired On   : $exp"
echo -e "\033[0;34m◇━━━━━━━━━━━━━━━━━◇\033[0m"
} | tee -a /etc/log-create-user.log
read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
menu
