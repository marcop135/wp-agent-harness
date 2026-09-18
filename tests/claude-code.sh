#!/usr/bin/env bash
#
# claude-code.sh — test layer 4: the real end-to-end chain.
#
#   Claude Code -> MCP -> MCP Adapter -> Abilities API -> MS WP Abilities
#               -> WordPress -> database
#
# Each step runs a separate headless `claude -p` turn with only the WordPress
# MCP server allowed, and every claim Claude makes is checked against the
# database with WP-CLI. Nothing here is simulated.
#
# Requires: ./bin/connect to have been run. Costs a handful of model turns.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_docker
require_env

have claude || die 'claude is not on PATH. Run ./bin/test --skip-claude to skip this layer.'

SERVER_NAME="$(env_get MCP_SERVER_NAME wordpress)"
RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
TEST_TITLE="MCP Integration Test $RUN_ID"
TEST_POST_ID=''

find_test_post() {
    wp_cli post list --post_type=page --post_status=any,trash \
        --title="$TEST_TITLE" --field=ID --format=csv 2>/dev/null | tr -d '\r' | head -1
}

cleanup() {
    local id="${TEST_POST_ID:-$(find_test_post)}"
    if [[ -n "$id" ]] && wp_cli post get "$id" --field=ID >/dev/null 2>&1; then
        wp_cli post delete "$id" --force >/dev/null 2>&1 \
            && note "Removed test content (post $id)" \
            || warn "Could not remove test post $id — delete it from wp-admin."
    fi
}
trap cleanup EXIT

# Run one headless Claude Code turn with only the WordPress MCP tools allowed.
ask_claude() {
    local prompt="$1" out
    out="$(
        cd "$REPO_ROOT" && claude -p "$prompt" \
            --output-format json \
            --allowedTools "mcp__${SERVER_NAME}" \
            --disallowedTools Bash Edit Write WebFetch WebSearch \
            --permission-prompts none \
            --no-session-persistence \
            2>/dev/null
    )" || return 1
    jq -r '.result // empty' <<<"$out"
}

# ===========================================================================
suite 'Layer 4 — Claude Code MCP configuration'
# ===========================================================================

assert_ok "MCP server '$SERVER_NAME' is registered for this project" \
    bash -c "cd '$REPO_ROOT' && claude mcp get '$SERVER_NAME' >/dev/null"

registration="$( cd "$REPO_ROOT" && claude mcp get "$SERVER_NAME" 2>&1 || true )"
assert_contains 'the registration uses the HTTP transport' "$registration" 'http'
assert_contains 'the registration points at the local MCP endpoint' \
    "$registration" "localhost:$(env_get WP_PORT 8080)"
assert_contains 'the registration carries the Basic auth header' \
    "$registration" 'Authorization: Basic'

# ===========================================================================
suite 'Layer 4 — Claude Code discovers and inspects the site'
# ===========================================================================

inspect="$(ask_claude "Using only the WordPress MCP server, inspect this site. \
Report, as a short plain-text list: the WordPress version, the active theme's slug, \
the slugs of all active plugins, and the site title. Do not change anything.")" \
    || _record_fail 'claude -p completed the inspection turn' 'the CLI exited non-zero'

wp_version="$(wp_cli core version 2>/dev/null | tr -d '\r')"
active_theme="$(wp_cli theme list --status=active --field=name 2>/dev/null | tr -d '\r')"
site_title="$(wp_cli option get blogname 2>/dev/null | tr -d '\r')"

assert_contains 'Claude reported the real WordPress version' "$inspect" "$wp_version"
assert_contains 'Claude reported the real active theme' "$inspect" "$active_theme"
assert_contains 'Claude reported the MCP Adapter plugin' "$inspect" 'mcp-adapter'
assert_contains 'Claude reported the MS WP Abilities plugin' "$inspect" 'ms-wp-abilities'
assert_contains 'Claude reported the real site title' "$inspect" "$site_title"

# ===========================================================================
suite 'Layer 4 — Claude Code creates a draft'
# ===========================================================================

ask_claude "Using the WordPress MCP server, create a new page with the exact title \
\"$TEST_TITLE\". Its status must be draft — do not publish it. Give it this markdown body, \
verbatim:

## Written by Claude Code

This page was created through the Model Context Protocol.

Reply with the numeric post ID and nothing else." >/dev/null \
    || _record_fail 'claude -p completed the creation turn' 'the CLI exited non-zero'

TEST_POST_ID="$(find_test_post)"
if [[ "$TEST_POST_ID" =~ ^[0-9]+$ ]]; then
    _record_pass "the database has the page Claude created (ID $TEST_POST_ID)"
else
    _record_fail 'the database has the page Claude created' \
        "no page titled '$TEST_TITLE' exists"
    test_summary
    exit 1
fi

assert_eq 'the page Claude created is a draft' 'draft' \
    "$(wp_cli post get "$TEST_POST_ID" --field=post_status 2>/dev/null | tr -d '\r')"
assert_eq 'the page Claude created is a page, not a post' 'page' \
    "$(wp_cli post get "$TEST_POST_ID" --field=post_type 2>/dev/null | tr -d '\r')"

created_content="$(wp_cli post get "$TEST_POST_ID" --field=content 2>/dev/null | tr -d '\r')"
assert_contains 'the page body reached the database' \
    "$created_content" 'created through the Model Context Protocol'
assert_contains 'the body is Gutenberg block markup' "$created_content" '<!-- wp:'

# ===========================================================================
suite 'Layer 4 — Claude Code reads the draft back'
# ===========================================================================

readback="$(ask_claude "Using the WordPress MCP server, find the draft page titled \
\"$TEST_TITLE\" and report its post ID, its status and the text of its heading. \
Do not change anything.")" \
    || _record_fail 'claude -p completed the read-back turn' 'the CLI exited non-zero'

assert_contains 'Claude read back the correct post ID' "$readback" "$TEST_POST_ID"
assert_contains 'Claude read back the draft status' "$readback" 'draft'
assert_contains 'Claude read back the heading text' "$readback" 'Written by Claude Code'

# ===========================================================================
suite 'Layer 4 — Claude Code modifies the draft'
# ===========================================================================

ask_claude "Using the WordPress MCP server, edit page ID $TEST_POST_ID. \
Replace the exact phrase \"Written by Claude Code\" with \"Verified by Claude Code\". \
Change nothing else. I approve this change in advance, so make it now without asking." >/dev/null \
    || _record_fail 'claude -p completed the modification turn' 'the CLI exited non-zero'

modified_content="$(wp_cli post get "$TEST_POST_ID" --field=content 2>/dev/null | tr -d '\r')"
assert_contains 'the modification is in the database' "$modified_content" 'Verified by Claude Code'
assert_not_contains 'the original heading text is gone' "$modified_content" 'Written by Claude Code'

# ===========================================================================
suite 'Layer 4 — Claude Code cleans up'
# ===========================================================================

ask_claude "Using the WordPress MCP server, move page ID $TEST_POST_ID to the trash. \
I approve this in advance. Then confirm its new status." >/dev/null \
    || _record_fail 'claude -p completed the cleanup turn' 'the CLI exited non-zero'

assert_eq 'the database confirms Claude trashed the page' 'trash' \
    "$(wp_cli post get "$TEST_POST_ID" --field=post_status 2>/dev/null | tr -d '\r')"

test_summary
