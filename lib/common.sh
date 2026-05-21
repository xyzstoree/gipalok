#!/bin/bash
# ============================================================================
# v7fix — common library
# Source-able from any script: source /etc/v7fix/lib/common.sh
# Idempotent: re-sourcing is safe.
# ============================================================================

# Guard against double-sourcing
[ -n "${V7FIX_COMMON_LOADED:-}" ] && return 0
V7FIX_COMMON_LOADED=1

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------
export V7FIX_BASE_DIR="${V7FIX_BASE_DIR:-/root/v7fix}"
export V7FIX_LIB_DIR="${V7FIX_LIB_DIR:-/etc/v7fix/lib}"
export V7FIX_STATE_DIR="${V7FIX_STATE_DIR:-/etc/v7fix}"
export V7FIX_LOG_DIR="${V7FIX_LOG_DIR:-/var/log/v7fix}"
export V7FIX_CACHE_DIR="${V7FIX_CACHE_DIR:-/var/cache/v7fix}"

# Legacy compatibility (gipalok) — keep paths working so users don't lose data
export ANGGUN_DIR="${ANGGUN_DIR:-/etc/Anggun}"
export ANGGUN_VAR="${ANGGUN_VAR:-/var/lib/Anggun}"

mkdir -p "$V7FIX_STATE_DIR" "$V7FIX_LOG_DIR" "$V7FIX_CACHE_DIR" \
         "$ANGGUN_DIR" "$ANGGUN_VAR" 2>/dev/null || true

# ----------------------------------------------------------------------------
# Colors
# ----------------------------------------------------------------------------
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
    export NC='\033[0m'
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[0;33m'
    export BLUE='\033[0;34m'
    export PURPLE='\033[0;35m'
    export CYAN='\033[0;36m'
    export LIGHT='\033[0;37m'
    export BOLD='\e[1m'
else
    export NC='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' LIGHT='' BOLD=''
fi

# ----------------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------------
_v7_log_to_file() {
    local level="$1" msg="$2"
    [ -d "$V7FIX_LOG_DIR" ] || return 0
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$msg" \
        >> "$V7FIX_LOG_DIR/v7fix.log" 2>/dev/null || true
}

info() { echo -e "${CYAN}[ INFO ]${NC} $*"; _v7_log_to_file INFO "$*"; }
ok()   { echo -e "${GREEN}[  OK  ]${NC} $*"; _v7_log_to_file OK   "$*"; }
warn() { echo -e "${YELLOW}[ WARN ]${NC} $*"; _v7_log_to_file WARN "$*"; }
fail() { echo -e "${RED}[ FAIL ]${NC} $*" >&2; _v7_log_to_file FAIL "$*"; }
die()  { fail "$*"; exit 1; }

# ----------------------------------------------------------------------------
# Validation
# ----------------------------------------------------------------------------
require_root() {
    if [ "$(id -u)" != "0" ]; then
        die "Script harus dijalankan sebagai root."
    fi
}

require_cmd() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || die "Command '$cmd' tidak ditemukan. Install dulu."
}

# Check supported OS (Ubuntu 18+/Debian 9+). Returns 0 if ok, 1 otherwise.
check_os() {
    [ -f /etc/os-release ] || { warn "Tidak bisa mendeteksi OS"; return 1; }
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
        ubuntu|debian) return 0 ;;
        *) warn "OS '$ID' tidak resmi didukung (hanya Ubuntu/Debian)"; return 1 ;;
    esac
}

# ----------------------------------------------------------------------------
# Network info — cached to avoid hammering ipinfo.io every menu render
# ----------------------------------------------------------------------------

# Detect default network interface (eth0 fallback)
v7_get_nic() {
    local cache="$V7FIX_CACHE_DIR/nic"
    if [ -f "$cache" ] && [ "$(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0)))" -lt 86400 ]; then
        cat "$cache"; return 0
    fi
    local nic
    nic=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
    [ -z "$nic" ] && nic=$(ip -o -4 route show to default 2>/dev/null | awk '{print $5; exit}')
    [ -z "$nic" ] && nic="eth0"
    echo "$nic" > "$cache" 2>/dev/null || true
    echo "$nic"
}

# Get public IP. Cache 1 hour. Tries multiple providers.
v7_get_ip() {
    local cache="$V7FIX_CACHE_DIR/ip"
    if [ -f "$cache" ] && [ "$(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0)))" -lt 3600 ]; then
        cat "$cache"; return 0
    fi
    local ip=""
    for url in "https://ipv4.icanhazip.com" "https://ifconfig.me" "https://ipinfo.io/ip"; do
        ip=$(curl -sS --max-time 3 "$url" 2>/dev/null | tr -d '[:space:]')
        if echo "$ip" | grep -Eq '^[0-9.]+$'; then break; fi
        ip=""
    done
    [ -z "$ip" ] && ip="-"
    echo "$ip" > "$cache" 2>/dev/null || true
    echo "$ip"
}

# Get domain — falls back to public IP
v7_get_domain() {
    local d
    d=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null)
    if [ -z "$d" ] || [ "$d" = "-" ]; then
        d=$(v7_get_ip)
    fi
    echo "$d"
}

# Get ISP & city, cached 6h. Returns "ISP|CITY".
v7_get_geo() {
    local cache="$V7FIX_CACHE_DIR/geo"
    if [ -f "$cache" ] && [ "$(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0)))" -lt 21600 ]; then
        cat "$cache"; return 0
    fi
    local isp city
    isp=$(curl -sS --max-time 2 "https://ipinfo.io/org" 2>/dev/null | sed 's/^AS[0-9]\+ //' | tr -d '\n')
    city=$(curl -sS --max-time 2 "https://ipinfo.io/city" 2>/dev/null | tr -d '\n')
    [ -z "$isp" ]  && isp="-"
    [ -z "$city" ] && city="-"
    printf '%s|%s' "$isp" "$city" > "$cache" 2>/dev/null || true
    printf '%s|%s' "$isp" "$city"
}

# ----------------------------------------------------------------------------
# Misc helpers
# ----------------------------------------------------------------------------

# Validate username: 2-32 chars, [a-zA-Z0-9_-], must start with alnum/_
v7_valid_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]{1,31}$ ]]
}

# Validate positive integer
v7_valid_int() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ]
}

# Pause and return to a menu command
v7_pause_back() {
    local back="${1:-menu}"
    echo ""
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali..."
    echo ""
    if command -v "$back" >/dev/null 2>&1; then
        "$back"
    fi
}

# Prompt yes/no, default no. Returns 0 for yes.
v7_confirm() {
    local prompt="${1:-Lanjut?} [y/N]: "
    local ans
    read -rp "$prompt" ans
    [[ "$ans" =~ ^[Yy]$ ]]
}
