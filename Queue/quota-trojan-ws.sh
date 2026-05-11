#!/bin/bash
# quota-trojan-ws.sh — Fixed
# FIX 1: Wrong port 10001 → 10085
# FIX 2: Parsing rewritten with proper -pattern flag
# FIX 3: Removed dead data1 check
STATS_PORT=10085
mkdir -p /etc/Anggun/trojan /etc/Anggun/cache/trojan-ws

run_data() {
    data=$(/usr/local/bin/xray api statsquery --server=127.0.0.1:${STATS_PORT} \
        -pattern "user>>>trojan-${user}>>>traffic" 2>/dev/null \
        | grep '"value"' | awk '{gsub(/[^0-9]/,"",$2); sum+=$2} END{print sum+0}')
    [ -z "$data" ] && data=0
}

run_file() {
    [ -f "/etc/Anggun/trojan/${user}"           ] && [ -s "/etc/Anggun/trojan/${user}"           ] || echo "0" > "/etc/Anggun/trojan/${user}"
    [ -f "/etc/Anggun/cache/trojan-ws/${user}"  ] && [ -s "/etc/Anggun/cache/trojan-ws/${user}"  ] || echo "0" > "/etc/Anggun/cache/trojan-ws/${user}"
}

run_sesi1() {
    local vlama vtotal vvar
    vlama=$(cat /etc/Anggun/cache/trojan-ws/$user)
    vtotal=$(cat /etc/Anggun/trojan/$user)
    if [[ $data -gt $vlama ]]; then
        vvar=$(( data - vlama ))
        echo $(( vvar + vtotal )) > /etc/Anggun/trojan/$user
    else
        echo $(( data + vtotal )) > /etc/Anggun/trojan/$user
    fi
    echo "$data" > /etc/Anggun/cache/trojan-ws/$user
}

run_inti() {
    run_data; run_file
    local vlama; vlama=$(cat /etc/Anggun/cache/trojan-ws/$user)
    [ "$vlama" != "$data" ] && run_sesi1
    echo "$data" > /etc/Anggun/cache/trojan-ws/$user
}

dataku=( $(/usr/local/bin/xray api statsquery --server=127.0.0.1:${STATS_PORT} \
    -pattern "user>>>trojan-" 2>/dev/null \
    | grep '"name"' | sed 's/.*user>>>\(trojan-[^>]*\)>>>.*/\1/' \
    | sed 's/^trojan-//' | sort | uniq) )
for user in "${dataku[@]}"; do
    run_inti
    sleep 0.1
done
