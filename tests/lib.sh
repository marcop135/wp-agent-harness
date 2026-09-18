#!/usr/bin/env bash
# Shared assertions and an MCP-over-HTTP client for the test suite.
# Sourced by tests/*.sh, never executed directly.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../bin" && pwd)/lib.sh"

have jq || die 'jq is required by the test suite.
    macOS    brew install jq
    Linux    sudo apt install jq   (or the equivalent for your distribution)
    Windows  winget install jqlang.jq'

# jq's native Windows build writes CRLF line endings, which would make every
# string comparison below platform-dependent. Normalise once, here.
jq() { command jq "$@" | tr -d '\r'; }

TEST_COUNT=0
TEST_FAIL=0
TEST_FAILURES=()

_record_pass() {
    TEST_COUNT=$((TEST_COUNT + 1))
    printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"
}

_record_fail() {
    TEST_COUNT=$((TEST_COUNT + 1))
    TEST_FAIL=$((TEST_FAIL + 1))
    TEST_FAILURES+=("$1")
    printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$1"
    [[ -n "${2:-}" ]] && printf '      %s\n' "${2//$'\n'/$'\n'      }"
    return 0
}

suite() { printf '\n%s%s%s\n' "$C_BOLD" "$1" "$C_RESET"; }

# assert_ok <description> <command...>
assert_ok() {
    local desc="$1"; shift
    local out status
    out="$("$@" 2>&1)" && status=0 || status=$?
    if [[ "$status" -eq 0 ]]; then
        _record_pass "$desc"
    else
        _record_fail "$desc" "exit $status: ${out:-(no output)}"
    fi
}

# assert_fails <description> <command...>  — the command is expected to fail
assert_fails() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        _record_fail "$desc" 'command unexpectedly succeeded'
    else
        _record_pass "$desc"
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        _record_pass "$desc"
    else
        _record_fail "$desc" "expected: $expected"$'\n'"actual:   $actual"
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        _record_pass "$desc"
    else
        _record_fail "$desc" "missing: $needle"$'\n'"in:      $(head -c 400 <<<"$haystack")"
    fi
}

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        _record_pass "$desc"
    else
        _record_fail "$desc" "unexpectedly present: $needle"
    fi
}

# assert_ge <description> <actual> <minimum>
assert_ge() {
    local desc="$1" actual="$2" minimum="$3"
    if [[ "${actual:-0}" =~ ^[0-9]+$ ]] && [[ "$actual" -ge "$minimum" ]]; then
        _record_pass "$desc ($actual)"
    else
        _record_fail "$desc" "expected >= $minimum, got: ${actual:-(empty)}"
    fi
}

test_summary() {
    printf '\n'
    if [[ "$TEST_FAIL" -eq 0 ]]; then
        printf '%s%d/%d checks passed.%s\n\n' "$C_GREEN$C_BOLD" "$TEST_COUNT" "$TEST_COUNT" "$C_RESET"
        return 0
    fi
    printf '%s%d of %d checks failed:%s\n' "$C_RED$C_BOLD" "$TEST_FAIL" "$TEST_COUNT" "$C_RESET"
    printf '  - %s\n' "${TEST_FAILURES[@]}"
    printf '\nDiagnostics: ./bin/status, ./bin/logs --debug, docs/troubleshooting.md\n\n'
    return 1
}

# ---------------------------------------------------------------------------
# Minimal MCP Streamable HTTP client.
#
# Implements the handshake the MCP Adapter documents: initialize, capture the
# Mcp-Session-Id header, send notifications/initialized, then carry the session
# header (and MCP-Protocol-Version) on every later request.
#
# Every call writes its result into MCP_LAST_* globals rather than printing it,
# because a command substitution would run the function in a subshell and throw
# the captured session ID away.
# ---------------------------------------------------------------------------

MCP_PROTOCOL_VERSION='2025-11-25'
MCP_SESSION_ID=''
MCP_NEGOTIATED_VERSION=''
MCP_SERVER_INFO=''
MCP_RPC_ID=0
MCP_LAST_STATUS=''
MCP_LAST_HEADERS=''
MCP_LAST_BODY=''

mcp_creds() {
    mcp_basic_auth 2>/dev/null \
        || die "No Application Password in ${APP_PASSWORD_FILE#"$REPO_ROOT/"}. Run ./bin/setup."
}

# mcp_request <json-body> — POST it, then fill MCP_LAST_STATUS/HEADERS/BODY.
mcp_request() {
    local args=(
        -sS -i -X POST
        --user "$(mcp_creds)"
        -H 'Content-Type: application/json'
        -H 'Accept: application/json, text/event-stream'
        # Suppress 100-continue so the response is a single header block.
        -H 'Expect:'
        -d "$1"
    )
    [[ -n "$MCP_SESSION_ID" ]] && args+=(-H "Mcp-Session-Id: $MCP_SESSION_ID")
    [[ -n "$MCP_NEGOTIATED_VERSION" ]] && args+=(-H "MCP-Protocol-Version: $MCP_NEGOTIATED_VERSION")

    local raw
    raw="$(curl "${args[@]}" "$(mcp_endpoint)" 2>/dev/null || true)"
    raw="${raw//$'\r'/}"

    MCP_LAST_HEADERS="${raw%%$'\n\n'*}"
    if [[ "$raw" == *$'\n\n'* ]]; then
        MCP_LAST_BODY="${raw#*$'\n\n'}"
    else
        MCP_LAST_BODY=''
    fi
    # shellcheck disable=SC2034  # read by the test scripts that source this file
    MCP_LAST_STATUS="$(awk 'NR==1 {print $2}' <<<"$MCP_LAST_HEADERS")"
}

mcp_next_id() { MCP_RPC_ID=$((MCP_RPC_ID + 1)); }

mcp_initialize() {
    MCP_SESSION_ID=''
    MCP_NEGOTIATED_VERSION=''
    mcp_request "$(jq -cn --arg v "$MCP_PROTOCOL_VERSION" \
        '{jsonrpc:"2.0",id:0,method:"initialize",params:{protocolVersion:$v,capabilities:{},clientInfo:{name:"wordpress-claude-mcp-tests",version:"1.0.0"}}}')"

    MCP_SESSION_ID="$(grep -i '^mcp-session-id:' <<<"$MCP_LAST_HEADERS" \
        | tail -n1 | cut -d: -f2- | tr -d '[:space:]')"
    MCP_NEGOTIATED_VERSION="$(jq -r '.result.protocolVersion // empty' <<<"$MCP_LAST_BODY" 2>/dev/null || true)"
    # shellcheck disable=SC2034  # read by the test scripts that source this file
    MCP_SERVER_INFO="$(jq -c '.result.serverInfo // {}' <<<"$MCP_LAST_BODY" 2>/dev/null || echo '{}')"
}

mcp_notify_initialized() {
    mcp_request '{"jsonrpc":"2.0","method":"notifications/initialized"}'
}

mcp_tools_list() {
    mcp_next_id
    mcp_request "$(jq -cn --argjson id "$MCP_RPC_ID" \
        '{jsonrpc:"2.0",id:$id,method:"tools/list",params:{}}')"
}

# mcp_tool_call <tool-name> <arguments-json>
mcp_tool_call() {
    mcp_next_id
    mcp_request "$(jq -cn --argjson id "$MCP_RPC_ID" --arg name "$1" --argjson args "$2" \
        '{jsonrpc:"2.0",id:$id,method:"tools/call",params:{name:$name,arguments:$args}}')"
}

# mcp_execute_ability <ability-name> <parameters-json> — the default server's
# execute-ability meta-tool, which is how every WordPress ability is reached.
mcp_execute_ability() {
    mcp_tool_call 'mcp-adapter-execute-ability' \
        "$(jq -cn --arg n "$1" --argjson p "$2" '{ability_name:$n,parameters:$p}')"
}

# Print the payload the last tools/call returned, unwrapped from the MCP
# envelope. The adapter fills structuredContent; the text block is the fallback.
mcp_payload() {
    jq -c '
        if .result.structuredContent then .result.structuredContent
        elif (.result.content[0].text? // null) then (.result.content[0].text | fromjson? // .)
        else .
        end' <<<"$MCP_LAST_BODY" 2>/dev/null || printf '%s' "$MCP_LAST_BODY"
}

# An ability that returns a WP_Error comes back as a successful JSON-RPC
# response carrying isError:true and a text block — not as a JSON-RPC error.
mcp_is_error() {
    jq -r '.result.isError // false' <<<"$MCP_LAST_BODY" 2>/dev/null || echo unknown
}

mcp_terminate() {
    [[ -n "$MCP_SESSION_ID" ]] || return 0
    curl -sS -i -X DELETE "$(mcp_endpoint)" \
        --user "$(mcp_creds)" \
        -H "Mcp-Session-Id: $MCP_SESSION_ID" >/dev/null 2>&1 || true
    MCP_SESSION_ID=''
}
