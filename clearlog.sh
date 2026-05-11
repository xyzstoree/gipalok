#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[0;34m'
LIGHT='\033[0;37m'

data=( $(find /var/log/ -name "*.log") );
for log in "${data[@]}"
do
echo "$log clear"
echo > $log
done
data=( $(find /var/log/ -name "*.err") );
for log in "${data[@]}"
do
echo "$log clear"
echo > $log
done
data=( $(find /var/log/ -name "mail.*") );
for log in "${data[@]}"
do
echo "$log clear"
echo > $log
done
echo > /var/log/syslog
echo > /var/log/btmp
echo > /var/log/messages
echo > /var/log/debug
echo -e "LOG BERHASIL DI HAPUS"
