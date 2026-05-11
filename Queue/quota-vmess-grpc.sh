#!/bin/bash
# quota-vmess-grpc.sh — Fixed
# FIX 1: Wrong port 10006 → 10085
# FIX 2: Parsing rewritten with proper -pattern flag
# FIX 3: Removed dead data1 check
STATS_PORT=10085
mkdir -p /etc/Anggun/vmess /etc/Anggun/cache/vmess-grpc

run_data() {
    data=$(/usr/local/bin/xray api statsquery --server=127.0.0.1:${STATS_PORT} \
        -pattern "user>>>vmess-${user}>>>traffic" 2>/dev/null \
        | grep '"value"' | awk '{gsub(/[^0-9]/,"",$2); sum+=$2} END{print sum+0}')
    [ -z "$data" ] && data=0
}

run_file() {
    [ -f "/etc/Anggun/vmess/${user}"           ] && [ -s "/etc/Anggun/vmess/${user}"           ] || echo "0" > "/etc/Anggun/vmess/${user}"
    [ -f "/etc/Anggun/cache/vmess-grpc/${user}"] && [ -s "/etc/Anggun/cache/vmess-grpc/${user}"] || echo "0" > "/etc/Anggun/cache/vmess-grpc/${user}"
}

run_sesi1() {
    local vlama vtotal vvar
    vlama=$(cat /etc/Anggun/cache/vmess-grpc/$user)
    vtotal=$(cat /etc/Anggun/vmess/$user)
    if [[ $data -gt $vlama ]]; then
        vvar=$(( data - vlama ))
        echo $(( vvar + vtotal )) > /etc/Anggun/vmess/$user
    else
        echo $(( data + vtotal )) > /etc/Anggun/vmess/$user
    fi
    echo "$data" > /etc/Anggun/cache/vmess-grpc/$user
}

run_inti() {
    run_data; run_file
    local vlama; vlama=$(cat /etc/Anggun/cache/vmess-grpc/$user)
    [ "$vlama" != "$data" ] && run_sesi1
    echo "$data" > /etc/Anggun/cache/vmess-grpc/$user
}

dataku=( $(/usr/local/bin/xray api statsquery --server=127.0.0.1:${STATS_PORT} \
    -pattern "user>>>vmess-" 2>/dev/null \
    | grep '"name"' | sed 's/.*user>>>\(vmess-[^>]*\)>>>.*/\1/' \
    | sed 's/^vmess-//' | sort | uniq) )
for user in "${dataku[@]}"; do
    run_inti
    sleep 0.1
done
