#!/bin/bash
# Fixed restart menu for gipalok
# - Skips services that are not installed instead of throwing errors
# - Supports both systemd and /etc/init.d services

clear

print_header() {
  echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo -e "\E[0;100;33m • RESTART MENU • \E[0m"
  echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo ""
}

pause_menu() {
  echo ""
  echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo ""
  read -n 1 -s -r -p "PRESS [ ENTER ] KELUAR MENU"
  restart 2>/dev/null || menu 2>/dev/null || exit 0
}

restart_service() {
  local svc="$1"
  local label="${2:-$svc}"

  if systemctl list-unit-files "${svc}.service" 2>/dev/null | grep -q "^${svc}.service"; then
    echo -e "[ \033[32mok\033[0m ] Restarting ${label} Service (via systemctl)"
    systemctl restart "${svc}.service" >/dev/null 2>&1 \
      && echo -e "[ \033[32mok\033[0m ] ${label} restarted" \
      || echo -e "[ \033[33mwarn\033[0m ] ${label} gagal restart"
  elif [ -x "/etc/init.d/${svc}" ]; then
    echo -e "[ \033[32mok\033[0m ] Restarting ${label} Service (via init.d)"
    /etc/init.d/"${svc}" restart >/dev/null 2>&1 \
      && echo -e "[ \033[32mok\033[0m ] ${label} restarted" \
      || echo -e "[ \033[33mwarn\033[0m ] ${label} gagal restart"
  else
    echo -e "[ \033[33mskip\033[0m ] ${label} tidak terinstall"
  fi
}

restart_badvpn() {
  if command -v badvpn-udpgw >/dev/null 2>&1 && command -v screen >/dev/null 2>&1; then
    pkill -f "badvpn-udpgw" >/dev/null 2>&1 || true
    screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
    echo -e "[ \033[32mok\033[0m ] Badvpn restarted"
  else
    echo -e "[ \033[33mskip\033[0m ] Badvpn/screen tidak terinstall"
  fi
}

print_header
echo -e " [\e[36m•1\e[0m] Restart All Services"
echo -e " [\e[36m•2\e[0m] Restart OpenSSH"
echo -e " [\e[36m•3\e[0m] Restart Dropbear"
echo -e " [\e[36m•4\e[0m] Restart Stunnel4"
echo -e " [\e[36m•5\e[0m] Restart OpenVPN"
echo -e " [\e[36m•6\e[0m] Restart Squid"
echo -e " [\e[36m•7\e[0m] Restart Nginx"
echo -e " [\e[36m•8\e[0m] Restart Badvpn"
echo -e " [\e[36m•9\e[0m] Restart XRAY"
echo -e " [\e[36m10\e[0m] Restart WEBSOCKET"
echo -e " [\e[36m11\e[0m] Restart Trojan Go"
echo ""
echo -e " [\e[31m•0\e[0m] \e[31mKEMBALI KE MENU\033[0m"
echo ""
echo -e "Press x or [ Ctrl+C ] • To-Exit"
echo ""
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
read -p " Select menu : " Restart
clear

case "$Restart" in
  1)
    print_header
    echo -e "[ \033[32mInfo\033[0m ] Restart Begin"
    sleep 1
    restart_service ssh "OpenSSH"
    restart_service dropbear "Dropbear"
    restart_service stunnel4 "Stunnel4"
    restart_service openvpn "OpenVPN"
    restart_service fail2ban "Fail2ban"
    restart_service cron "Cron"
    restart_service nginx "Nginx"
    restart_service squid "Squid"
    restart_service xray "XRAY"
    restart_badvpn
    restart_service sshws "SSH WebSocket"
    restart_service ws-dropbear "WS Dropbear"
    restart_service ws-stunnel "WS Stunnel"
    restart_service trojan-go "Trojan Go"
    echo -e "[ \033[32mInfo\033[0m ] ALL Service Restarted / Skipped"
    pause_menu
    ;;
  2) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_service ssh "OpenSSH"; pause_menu ;;
  3) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_service dropbear "Dropbear"; pause_menu ;;
  4) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_service stunnel4 "Stunnel4"; pause_menu ;;
  5) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_service openvpn "OpenVPN"; pause_menu ;;
  6) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_service squid "Squid"; pause_menu ;;
  7) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_service nginx "Nginx"; pause_menu ;;
  8) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_badvpn; pause_menu ;;
  9) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_service xray "XRAY"; pause_menu ;;
  10)
    print_header
    echo -e "[ \033[32mInfo\033[0m ] Restart Begin"
    restart_service sshws "SSH WebSocket"
    restart_service ws-dropbear "WS Dropbear"
    restart_service ws-stunnel "WS Stunnel"
    pause_menu
    ;;
  11) print_header; echo -e "[ \033[32mInfo\033[0m ] Restart Begin"; restart_service trojan-go "Trojan Go"; pause_menu ;;
  0) menu 2>/dev/null || exit 0 ;;
  x|X) clear; exit 0 ;;
  *) echo "Pilihan tidak valid"; sleep 1; restart 2>/dev/null || exit 1 ;;
esac
