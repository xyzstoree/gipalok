#!/bin/bash
# Wrapper speedtest -> jalankan speedtest_cli.py
SPEED_PY="/root/gipalok/ssh/speedtest_cli.py"
[ ! -f "$SPEED_PY" ] && SPEED_PY="$(dirname "$0")/speedtest_cli.py"
if [ -f "$SPEED_PY" ]; then
    python3 "$SPEED_PY" --secure "$@"
else
    echo "speedtest_cli.py tidak ditemukan."
    exit 1
fi

