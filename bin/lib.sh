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
