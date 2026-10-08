#!/usr/bin/env bash
# Shared helpers for the ./bin commands. Sourced, never executed.

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly ENV_FILE="$REPO_ROOT/.env"
# shellcheck disable=SC2034  # read by bin/setup, which sources this file
readonly ENV_EXAMPLE="$REPO_ROOT/.env.example"
readonly SECRETS_DIR="$REPO_ROOT/.secrets"
readonly APP_PASSWORD_FILE="$SECRETS_DIR/application-password"

if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
    C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
else
    C_RESET=''; C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''
fi
readonly C_RESET C_BOLD C_DIM C_RED C_GREEN C_YELLOW

step() { printf '\n%s==> %s%s\n' "$C_BOLD" "$*" "$C_RESET"; }
info() { printf '    %s\n' "$*"; }
note() { printf '    %s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
ok()   { printf '    %sok%s   %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '    %swarn%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '\n%serror%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# --- prerequisites ---------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

require_docker() {
    have docker || die 'docker is not installed or not on PATH. See docs/troubleshooting.md.'
    docker compose version >/dev/null 2>&1 \
        || die 'docker compose (v2) is unavailable. Update Docker or install the compose plugin.'
    docker info >/dev/null 2>&1 \
        || die 'The Docker daemon is not running. Start Docker Desktop (or dockerd) and retry.'
}

require_env() {
    [[ -f "$ENV_FILE" ]] || die ".env is missing. Run: cp .env.example .env && ./bin/setup"
    if grep -qE '^[A-Z_]+=CHANGE_ME[[:space:]]*$' "$ENV_FILE"; then
        die '.env still contains CHANGE_ME placeholders. Run ./bin/setup to fill them in.'
    fi
}

# Read one key from .env without sourcing it.
env_get() {
    local key="$1" default="${2-}" line
    line="$(grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | tail -n1 || true)"
    if [[ -z "$line" ]]; then
        printf '%s' "$default"
    else
        printf '%s' "${line#*=}"
    fi
}

# --- docker compose --------------------------------------------------------

# Run from the repository root so Compose picks up docker-compose.yml and .env
# on its own. Passing --env-file would hand Docker a Unix-style path that the
# Windows binary cannot resolve.
dc() {
    ( cd "$REPO_ROOT" && docker compose "$@" )
}

# Run a command inside the WordPress container, no TTY.
#
# MSYS_NO_PATHCONV stops Git Bash on Windows rewriting container paths such as
# /var/www/html into Windows paths before Docker sees them. It is set here and
# nowhere else, because the same rewriting is what makes /dev/null and /tmp
# work for the native curl and mktemp binaries elsewhere in these scripts.
wpx() {
    (
        cd "$REPO_ROOT" \
            && MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
               docker compose exec -T wordpress "$@"
    )
}

wp_cli() {
    wpx wp "$@"
}

container_running() {
    local service="$1" id
    id="$(dc ps -q "$service" 2>/dev/null || true)"
    [[ -n "$id" ]] && [[ "$(docker inspect -f '{{.State.Running}}' "$id" 2>/dev/null || echo false)" == 'true' ]]
}

# --- site / MCP addresses --------------------------------------------------

readonly MCP_ROUTE='/wp-json/mcp/mcp-adapter-default-server'

# curl's `-o /dev/null` is not portable: under Git Bash the native curl binary
# treats /dev/null as a literal filename. These helpers keep the body on stdout
# instead and read the status from the last line.

# http_status <url> [curl args...]
http_status() {
    local url="$1"; shift
    local out
    out="$(curl -sS -w $'\n%{http_code}' "$@" "$url" 2>/dev/null || true)"
    printf '%s' "${out##*$'\n'}"
}

# http_headers <url> [curl args...] — response status line and headers only.
http_headers() {
    local url="$1"; shift
    curl -sS -i "$@" "$url" 2>/dev/null | sed -n '1,/^[[:space:]]*$/p'
}

site_url()     { printf 'http://localhost:%s' "$(env_get WP_PORT 8080)"; }
mcp_endpoint() { printf '%s%s' "$(site_url)" "$MCP_ROUTE"; }

app_password() {
    [[ -f "$APP_PASSWORD_FILE" ]] || return 1
    tr -d '\r\n' < "$APP_PASSWORD_FILE"
}

# Basic credentials for the MCP endpoint: admin login + Application Password.
mcp_basic_auth() {
    local pass
    pass="$(app_password)" || return 1
    printf '%s:%s' "$(env_get WP_ADMIN_USER admin)" "$pass"
}

# --- secret file modes -----------------------------------------------------

# True when chmod/stat modes are meaningful on this repo's filesystem
# (WSL /mnt/c and some NTFS mounts report 777 regardless of chmod).
modes_enforceable() {
    local probe="$REPO_ROOT/.mode-probe.$$"
    : >"$probe" || return 1
    chmod 600 "$probe" 2>/dev/null || { rm -f "$probe"; return 1; }
    local mode
    mode="$(stat -c '%a' "$probe" 2>/dev/null || stat -f '%OLp' "$probe" 2>/dev/null || echo '')"
    rm -f "$probe"
    mode="${mode#0}"
    [[ "$mode" == '600' ]]
}

secure_chmod() {
    local mode="$1" path="$2"
    chmod "$mode" "$path" 2>/dev/null || die "cannot chmod $mode $path"
    if modes_enforceable; then
        local got
        got="$(stat -c '%a' "$path" 2>/dev/null || stat -f '%OLp' "$path" 2>/dev/null || echo '')"
        # macOS stat -f %OLp may return 600 without leading zero; normalize.
        got="${got#0}"
        local want="${mode#0}"
        [[ "$got" == "$want" ]] || die "chmod $mode $path did not stick (mode=$got)"
    fi
}

# --- loopback bindings -----------------------------------------------------

# Return 0 when every published service port binds to 127.0.0.1 and no
# service uses network_mode: host (which ignores ports and binds all
# interfaces). Prints a reason on stderr and returns 1 on failure.
check_loopback_bindings() {
    local override="$REPO_ROOT/docker-compose.override.yml"
    if [[ -f "$override" ]]; then
        if grep -qEi '^\s*network_mode:\s*["'\'']?host["'\'']?\s*$' "$override"; then
            printf 'docker-compose.override.yml sets network_mode: host; that exposes the site beyond loopback (docs/security.md)\n' >&2
            return 1
        fi
        # Short-form publishes without an explicit 127.0.0.1 host (0.0.0.0,
        # bare host:container, or quoted variants). Long-form / merged
        # config is caught by the jq check below when Docker is available.
        if grep -qE '^\s*-\s*["'\'']?0\.0\.0\.0:' "$override" \
            || grep -qE '^\s*-\s*["'\'']?[0-9]+:[0-9]+' "$override"; then
            printf 'docker-compose.override.yml publishes a non-loopback port; bind to 127.0.0.1 (docs/security.md)\n' >&2
            return 1
        fi
    fi

    have docker || return 0
    docker info >/dev/null 2>&1 || return 0
    [[ -f "$ENV_FILE" ]] || return 0

    local cfg bad host_modes
    cfg="$(dc config --format json 2>/dev/null)" || return 0

    host_modes="$(printf '%s' "$cfg" | jq -r '
        .services // {}
        | to_entries[]
        | select((.value.network_mode // "") == "host")
        | .key
    ' 2>/dev/null || true)"
    if [[ -n "$host_modes" ]]; then
        printf 'Compose network_mode: host on %s; that exposes the site beyond loopback (docs/security.md)\n' \
            "$(tr '\n' ' ' <<<"$host_modes")" >&2
        return 1
    fi

    bad="$(printf '%s' "$cfg" | jq -r '
        .services // {}
        | to_entries[]
        | .key as $svc
        | (.value.ports // [])[]
        | select((.host_ip // "") != "127.0.0.1")
        | "\($svc) host_ip=\(.host_ip // "<empty>")"
    ' 2>/dev/null || true)"
    if [[ -n "$bad" ]]; then
        printf 'Compose port not bound to 127.0.0.1: %s (docs/security.md)\n' "$(tr '\n' '; ' <<<"$bad")" >&2
        return 1
    fi
    return 0
}

require_loopback_bindings() {
    local err
    if ! err="$(check_loopback_bindings 2>&1)"; then
        die "$err"
    fi
}
