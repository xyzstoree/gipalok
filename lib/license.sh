#!/bin/bash
# ============================================================================
# v7fix — license check
# Source of truth: https://raw.githubusercontent.com/xyzstoree/izin/main/ip
# Format per line: "### USERNAME YYYY-MM-DD IP"
#
# Behavior (fixes the gipalok bug "tetap expired walau tanggal di repo
# diupdate"):
#   - Always tries to refresh from the remote on every menu render.
#   - Cache TTL 5 minutes for fast subsequent renders.
#   - If cached entry says EXPIRED, the next fetch IGNORES the TTL (bypass
#     cache). So the moment the admin extends the date in repo izin, the
#     VPS picks it up immediately on the next menu render.
#   - If the remote is unreachable, fall back to cache as long as it is
#     < 7 days old (offline grace period).
#   - If the VPS IP is not registered at all, BLOCK menu access.
#
# Public functions:
#   v7_license_refresh      - force a fetch (bypass TTL), return 0 on success
#   v7_license_check        - run on every menu render, set globals below,
#                             exit script with code 2 if access denied
#
# Globals set by v7_license_check (read-only for callers):
#   LICENSE_OK         "1" if access allowed, else "0"
#   LICENSE_USER       Username from repo izin
#   LICENSE_EXP        YYYY-MM-DD from repo izin
#   LICENSE_DAYS_LEFT  Days remaining (negative if expired)
#   LICENSE_STATUS     "active" | "expired" | "unregistered" | "offline-cache"
# ============================================================================

[ -n "${V7FIX_LICENSE_LOADED:-}" ] && return 0
V7FIX_LICENSE_LOADED=1

# Ensure common.sh is loaded
if [ -z "${V7FIX_COMMON_LOADED:-}" ]; then
    if [ -f /etc/v7fix/lib/common.sh ]; then
        # shellcheck disable=SC1091
        source /etc/v7fix/lib/common.sh
    fi
fi

# Configuration
V7FIX_LICENSE_URL="${V7FIX_LICENSE_URL:-https://raw.githubusercontent.com/xyzstoree/izin/main/ip}"
V7FIX_LICENSE_CACHE="${V7FIX_LICENSE_CACHE:-/var/cache/v7fix/license}"
V7FIX_LICENSE_TTL="${V7FIX_LICENSE_TTL:-300}"        # 5 minutes
V7FIX_LICENSE_OFFLINE_TTL="${V7FIX_LICENSE_OFFLINE_TTL:-604800}"  # 7 days

mkdir -p "$(dirname "$V7FIX_LICENSE_CACHE")" 2>/dev/null || true

# ----------------------------------------------------------------------------
# Internal: parse the cached file for our IP, set LICENSE_* globals
# ----------------------------------------------------------------------------
_v7_license_parse() {
    local file="$1" ip="$2"
    LICENSE_OK=0
    LICENSE_USER=""
    LICENSE_EXP=""
    LICENSE_DAYS_LEFT=""
    LICENSE_STATUS="unregistered"

    [ -s "$file" ] || return 1

    # Match line "### USER YYYY-MM-DD IP"
    local line user exp ipfound
    # awk picks the LAST matching line in case of duplicates
    line=$(awk -v ip="$ip" '$1=="###" && $4==ip {last=$0} END{print last}' "$file")
    [ -z "$line" ] && return 1

    user=$(echo "$line" | awk '{print $2}')
    exp=$(echo "$line"  | awk '{print $3}')
    ipfound=$(echo "$line" | awk '{print $4}')

    [ "$ipfound" = "$ip" ] || return 1
    [ -z "$exp" ] && return 1

    LICENSE_USER="$user"
    LICENSE_EXP="$exp"

    local exp_ts now_ts
    exp_ts=$(date -d "$exp 23:59:59" +%s 2>/dev/null || echo 0)
    now_ts=$(date +%s)

    if [ "$exp_ts" -le 0 ]; then
        LICENSE_STATUS="unregistered"
        return 1
    fi

    LICENSE_DAYS_LEFT=$(( (exp_ts - now_ts) / 86400 ))

    if [ "$exp_ts" -gt "$now_ts" ]; then
        LICENSE_OK=1
        LICENSE_STATUS="active"
        return 0
    else
        LICENSE_STATUS="expired"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Internal: download fresh copy
# ----------------------------------------------------------------------------
_v7_license_fetch() {
    local tmp
    tmp=$(mktemp 2>/dev/null) || tmp="/tmp/v7fix-license.$$"
    if curl -fsSL --max-time 5 "$V7FIX_LICENSE_URL" -o "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        mv "$tmp" "$V7FIX_LICENSE_CACHE"
        chmod 600 "$V7FIX_LICENSE_CACHE" 2>/dev/null || true
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# ----------------------------------------------------------------------------
# Public: force refresh
# ----------------------------------------------------------------------------
v7_license_refresh() {
    _v7_license_fetch
}

# ----------------------------------------------------------------------------
# Public: main check
#
# Logic flow:
#   1. Read cache, parse against current VPS IP.
#   2. Decide if we MUST refresh:
#      - Cache missing OR
#      - Cache older than V7FIX_LICENSE_TTL OR
#      - Cached status is NOT 'active' (covers expired & unregistered —
#        this is the bug fix).
#   3. If must-refresh and fetch succeeds → re-parse.
#   4. If must-refresh and fetch fails → keep old cache only if it is still
#      within V7FIX_LICENSE_OFFLINE_TTL; otherwise treat as denied.
#   5. Block (exit 2) when LICENSE_OK is 0.
# ----------------------------------------------------------------------------
v7_license_check() {
    local skip_block="${1:-}"     # pass --no-exit to just set globals
    local ip cache_age=99999999 must_refresh=1

    ip=$(v7_get_ip 2>/dev/null)
    if [ -z "$ip" ] || [ "$ip" = "-" ]; then
        LICENSE_OK=0
        LICENSE_STATUS="offline-cache"
        warn "Tidak bisa mendeteksi IP publik VPS — cek koneksi internet."
        [ "$skip_block" = "--no-exit" ] && return 1
        exit 2
    fi

    if [ -f "$V7FIX_LICENSE_CACHE" ]; then
        cache_age=$(( $(date +%s) - $(stat -c %Y "$V7FIX_LICENSE_CACHE" 2>/dev/null || echo 0) ))
        # First parse the existing cache so we can decide
        _v7_license_parse "$V7FIX_LICENSE_CACHE" "$ip" || true
        # If cache says active AND fresh → no refresh needed
        if [ "$LICENSE_OK" = "1" ] && [ "$cache_age" -lt "$V7FIX_LICENSE_TTL" ]; then
            must_refresh=0
        fi
    fi

    if [ "$must_refresh" = "1" ]; then
        if _v7_license_fetch; then
            _v7_license_parse "$V7FIX_LICENSE_CACHE" "$ip" || true
        else
            # offline — fall back to old cache if within offline grace
            if [ -f "$V7FIX_LICENSE_CACHE" ] \
               && [ "$cache_age" -lt "$V7FIX_LICENSE_OFFLINE_TTL" ] \
               && [ "${LICENSE_OK:-0}" = "1" ]; then
                LICENSE_STATUS="offline-cache"
                # keep LICENSE_OK from previous parse (was 1)
            else
                LICENSE_OK=0
                LICENSE_STATUS="${LICENSE_STATUS:-offline-cache}"
            fi
        fi
    fi

    # Decide
    if [ "${LICENSE_OK:-0}" = "1" ]; then
        return 0
    fi

    # Denied — print user-friendly message
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}        AKSES SCRIPT DITOLAK${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    case "$LICENSE_STATUS" in
        expired)
            echo -e " IP VPS    : ${YELLOW}$ip${NC}"
            echo -e " User      : ${LICENSE_USER:-?}"
            echo -e " Expired   : ${RED}$LICENSE_EXP${NC}"
            echo -e " Status    : ${RED}EXPIRED${NC}"
            echo ""
            echo -e " Hubungi admin untuk perpanjang lisensi."
            echo -e " Setelah admin update tanggal di repo izin,"
            echo -e " ${GREEN}akses akan otomatis aktif tanpa perlu reinstall${NC}."
            ;;
        unregistered)
            echo -e " IP VPS    : ${YELLOW}$ip${NC}"
            echo -e " Status    : ${RED}IP TIDAK TERDAFTAR${NC}"
            echo ""
            echo -e " Daftarkan IP ini ke admin untuk dapat menggunakan script."
            ;;
        offline-cache|*)
            echo -e " IP VPS    : ${YELLOW}$ip${NC}"
            echo -e " Status    : ${RED}Tidak bisa fetch lisensi & cache expired${NC}"
            echo ""
            echo -e " Cek koneksi internet VPS, lalu coba lagi."
            ;;
    esac
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    [ "$skip_block" = "--no-exit" ] && return 1
    exit 2
}
