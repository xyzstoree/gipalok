#!/bin/bash
# ============================================================================
# v7fix — manifest installer (shared by updatemenu.sh and force-install.sh)
# Source-able. Provides: v7_install_manifest <repo_root_or_raw_base> [mode]
#
# Modes:
#   local  - copy from BASE_DIR/<src>
#   raw    - download from RAW_URL/<src>
# ============================================================================

[ -n "${V7FIX_INSTALL_MANIFEST_LOADED:-}" ] && return 0
V7FIX_INSTALL_MANIFEST_LOADED=1

# shellcheck source=/dev/null
[ -f /etc/v7fix/lib/common.sh ] && source /etc/v7fix/lib/common.sh

V7_OK_LIST=(); V7_FAIL_LIST=(); V7_MISS_LIST=()

# Args:
#   $1 = base (filesystem path or RAW URL)
#   $2 = mode "local" | "raw"
#   $3 = manifest file path (defaults to install/manifest.txt under base)
v7_install_manifest() {
    local base="$1" mode="${2:-local}" manifest="${3:-}"

    [ -z "$manifest" ] && {
        if [ "$mode" = "local" ]; then
            manifest="$base/install/manifest.txt"
        else
            local tmp; tmp=$(mktemp)
            if curl -fsSL --max-time 10 "${base}/install/manifest.txt" -o "$tmp" && [ -s "$tmp" ]; then
                manifest="$tmp"
            else
                rm -f "$tmp"; fail "Gagal download manifest dari $base"; return 1
            fi
        fi
    }

    [ -f "$manifest" ] || { fail "Manifest tidak ditemukan: $manifest"; return 1; }

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"
        [ -z "$line" ] && continue

        # shellcheck disable=SC2206
        local cols=( $line )
        local src="${cols[0]}" dst="${cols[1]}" alias="${cols[2]:-}"
        [ -z "$src" ] || [ -z "$dst" ] && continue

        mkdir -p "$(dirname "$dst")"
        local tmp="${dst}.tmp"

        if [ "$mode" = "local" ]; then
            if [ -f "$base/$src" ]; then
                cp "$base/$src" "$tmp" 2>/dev/null
            fi
        else
            curl -fsSL --max-time 15 "$base/$src" -o "$tmp" 2>/dev/null || true
        fi

        if [ -s "$tmp" ]; then
            mv "$tmp" "$dst"
            chmod +x "$dst" 2>/dev/null || true
            V7_OK_LIST+=("$dst")
            ok "Installed: $dst"
            if [ -n "$alias" ]; then
                cp "$dst" "$alias" 2>/dev/null && chmod +x "$alias" 2>/dev/null || true
            fi
        else
            rm -f "$tmp" 2>/dev/null
            if [ "$mode" = "local" ]; then
                V7_MISS_LIST+=("$src -> $dst")
                warn "MISS: $src"
            else
                V7_FAIL_LIST+=("$src -> $dst")
                fail "FAIL: $src"
            fi
        fi
    done < "$manifest"

    install_libs "$base" "$mode"
}

install_libs() {
    local base="$1" mode="${2:-local}"
    mkdir -p /etc/v7fix/lib

    for lib in common.sh license.sh; do
        local target="/etc/v7fix/lib/$lib"
        local tmp="${target}.tmp"

        if [ "$mode" = "local" ]; then
            [ -f "$base/lib/$lib" ] && cp "$base/lib/$lib" "$tmp"
        else
            curl -fsSL --max-time 15 "$base/lib/$lib" -o "$tmp" 2>/dev/null || true
        fi

        if [ -s "$tmp" ]; then
            mv "$tmp" "$target"
            chmod 644 "$target"
            ok "Lib: $target"
        else
            rm -f "$tmp"
            warn "Lib gagal install: $lib"
        fi
    done
}

v7_install_summary() {
    echo ""
    echo -e "${BLUE:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"
    echo -e "${GREEN:-}        INSTALL SCRIPT SELESAI${NC:-}"
    echo -e "${BLUE:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"
    echo -e "OK     : ${#V7_OK_LIST[@]}"
    echo -e "MISS   : ${#V7_MISS_LIST[@]}"
    echo -e "FAIL   : ${#V7_FAIL_LIST[@]}"
    if [ "${#V7_MISS_LIST[@]}" -gt 0 ] || [ "${#V7_FAIL_LIST[@]}" -gt 0 ]; then
        for item in "${V7_MISS_LIST[@]}"; do echo -e "${YELLOW:-}[ MISS ]${NC:-} $item"; done
        for item in "${V7_FAIL_LIST[@]}"; do echo -e "${RED:-}[ FAIL ]${NC:-} $item"; done
    fi
    echo -e "${BLUE:-}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC:-}"
}
