#!/usr/bin/env bash
#
# integration.sh — test layer 3: the MCP protocol itself.
#
# Speaks MCP Streamable HTTP to /wp-json/mcp/mcp-adapter-default-server exactly
# as an MCP client does — initialize, session header, notifications/initialized,
# tools/list, tools/call — and drives a full create / read / modify / verify /
# trash cycle through the abilities. HTTP 200 alone is never treated as a pass.
#
# Test content is uniquely named and removed again before the script exits.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_docker
require_env

RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
TEST_TITLE="MCP Integration Test $RUN_ID"
TEST_POST_ID=''

cleanup() {
    mcp_terminate
    if [[ -n "$TEST_POST_ID" ]] && wp_cli post get "$TEST_POST_ID" --field=ID >/dev/null 2>&1; then
        if wp_cli post delete "$TEST_POST_ID" --force >/dev/null 2>&1; then
            note "Removed test content (post $TEST_POST_ID)"
        else
            warn "Could not remove test post $TEST_POST_ID — delete it from wp-admin."
        fi
    fi
}
trap cleanup EXIT

# ===========================================================================
suite 'Layer 3 — MCP transport and authentication'
# ===========================================================================

assert_eq 'unauthenticated initialize is refused with HTTP 401' '401' \
    "$(http_status "$(mcp_endpoint)" -X POST \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}')"

assert_eq 'a wrong Application Password is refused with HTTP 401' '401' \
    "$(http_status "$(mcp_endpoint)" -X POST \
        --user "$(env_get WP_ADMIN_USER admin):definitely not the application password" \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}')"

# ===========================================================================
suite 'Layer 3 — MCP initialization handshake'
# ===========================================================================

mcp_initialize
assert_eq 'initialize returns HTTP 200' '200' "$MCP_LAST_STATUS"
assert_ok 'initialize returns a JSON-RPC result' jq -e '.result' <<<"$MCP_LAST_BODY"

if [[ -n "$MCP_SESSION_ID" ]]; then
    _record_pass "server issued an Mcp-Session-Id (${MCP_SESSION_ID:0:8}…)"
else
    _record_fail 'server issued an Mcp-Session-Id' "headers: $MCP_LAST_HEADERS"
fi

assert_eq 'server negotiated the requested protocol version' \
    "$MCP_PROTOCOL_VERSION" "$MCP_NEGOTIATED_VERSION"

assert_contains 'initialize advertises the MCP Adapter default server' \
    "$(jq -r '.name // "none"' <<<"$MCP_SERVER_INFO")" 'MCP Adapter'

assert_eq 'server advertises the tools capability' 'true' \
    "$(jq -r '.result.capabilities.tools != null' <<<"$MCP_LAST_BODY")"

# A request without the session header must be rejected — this proves the
# session really is enforced rather than ignored.
no_session="$(curl -sS -X POST "$(mcp_endpoint)" \
    --user "$(mcp_creds)" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":99,"method":"tools/list","params":{}}' 2>/dev/null || true)"
assert_contains 'tools/list without Mcp-Session-Id is rejected' "$no_session" 'error'

mcp_notify_initialized
assert_eq 'notifications/initialized is accepted with HTTP 202' '202' "$MCP_LAST_STATUS"

# ===========================================================================
suite 'Layer 3 — tool discovery'
# ===========================================================================

mcp_tools_list
assert_eq 'tools/list returns HTTP 200' '200' "$MCP_LAST_STATUS"

# The default server deliberately exposes three meta-tools rather than one tool
# per ability. See docs/architecture.md.
assert_eq 'tools/list exposes exactly the three MCP Adapter meta-tools' \
    'mcp-adapter-discover-abilities mcp-adapter-execute-ability mcp-adapter-get-ability-info ' \
    "$(jq -r '.result.tools[].name' <<<"$MCP_LAST_BODY" 2>/dev/null | sort | tr '\n' ' ')"

mcp_tool_call 'mcp-adapter-discover-abilities' '{}'
assert_eq 'discover-abilities returns HTTP 200' '200' "$MCP_LAST_STATUS"
ability_names="$(mcp_payload | jq -r '(.abilities // [])[].name' 2>/dev/null || true)"
assert_ge 'discover-abilities returns the public abilities' \
    "$(grep -c . <<<"$ability_names" || echo 0)" 20

for ability in miriamschwab/create-post miriamschwab/get-pages \
               miriamschwab/patch-post-content miriamschwab/trash-post \
               core/get-site-info; do
    if grep -qx "$ability" <<<"$ability_names"; then
        _record_pass "discover-abilities lists $ability"
    else
        _record_fail "discover-abilities lists $ability" 'not returned'
    fi
done

mcp_tool_call 'mcp-adapter-get-ability-info' '{"ability_name":"miriamschwab/create-post"}'
info_payload="$(mcp_payload)"
assert_eq 'get-ability-info returns the requested ability' \
    'miriamschwab/create-post' "$(jq -r '.name // empty' <<<"$info_payload")"
assert_eq 'get-ability-info returns an input schema with a required title' 'true' \
    "$(jq -r '[(.input_schema.required // [])[]] | index("title") != null' <<<"$info_payload")"

# The adapter's own meta-abilities are excluded from the public set.
mcp_tool_call 'mcp-adapter-get-ability-info' '{"ability_name":"mcp-adapter/execute-ability"}'
assert_eq 'abilities outside the public set are not exposed' 'true' "$(mcp_is_error)"
assert_contains 'the refusal names the MCP exposure rule' \
    "$MCP_LAST_BODY" 'not exposed via MCP'

# ===========================================================================
suite 'Layer 3 — ability execution (read)'
# ===========================================================================

mcp_execute_ability 'core/get-site-info' '{}'
site_info="$(mcp_payload)"
assert_eq 'execute-ability reports success for core/get-site-info' 'true' \
    "$(jq -r '.success // false' <<<"$site_info")"
assert_contains 'core/get-site-info returns this site' \
    "$site_info" "localhost:$(env_get WP_PORT 8080)"

mcp_execute_ability 'miriamschwab/get-post-types' '{}'
assert_contains 'get-post-types returns the built-in page type' "$(mcp_payload)" 'page'

mcp_execute_ability 'miriamschwab/get-plugins' '{}'
plugins="$(mcp_payload)"
assert_contains 'get-plugins reports the MCP Adapter' "$plugins" 'mcp-adapter'
assert_contains 'get-plugins reports MS WP Abilities' "$plugins" 'ms-wp-abilities'

mcp_execute_ability 'miriamschwab/get-themes' '{}'
assert_contains 'get-themes reports the active theme' \
    "$(mcp_payload)" "$(env_get WP_THEME twentytwentyfive)"

# ===========================================================================
suite 'Layer 3 — ability execution (create, modify, verify, trash)'
# ===========================================================================

mcp_execute_ability 'miriamschwab/create-post' "$(jq -cn --arg t "$TEST_TITLE" '{
    title: $t,
    post_type: "page",
    status: "draft",
    markdown: "## Created over MCP\n\nThis page was created by tests/integration.sh and is removed again when the run finishes.\n\n- first item\n- second item\n"
}')"
created="$(mcp_payload)"

assert_eq 'create-post reports success' 'true' "$(jq -r '.success // false' <<<"$created")"
TEST_POST_ID="$(jq -r '.data.ID // empty' <<<"$created")"

if [[ "$TEST_POST_ID" =~ ^[0-9]+$ ]]; then
    _record_pass "create-post returned post ID $TEST_POST_ID"
else
    _record_fail 'create-post returned a post ID' "payload: $(head -c 400 <<<"$created")"
    test_summary
    exit 1
fi

assert_eq 'the new page is a draft, not published' 'draft' \
    "$(jq -r '.data.status // empty' <<<"$created")"

# Read it back over MCP.
mcp_execute_ability 'miriamschwab/get-pages' \
    "$(jq -cn --arg s "$TEST_TITLE" '{search:$s,status:"draft"}')"
assert_eq 'get-pages finds the page just created' "$TEST_POST_ID" \
    "$(mcp_payload | jq -r --argjson id "$TEST_POST_ID" \
        '(.data // [])[] | select(.ID == $id) | .ID | tostring' | head -1)"

# Markdown really was converted to Gutenberg blocks server-side.
stored_content="$(wp_cli post get "$TEST_POST_ID" --field=content 2>/dev/null | tr -d '\r' || true)"
assert_contains 'markdown was converted to Gutenberg blocks' "$stored_content" '<!-- wp:heading'
assert_contains 'the block content contains the list' "$stored_content" '<!-- wp:list'

# Modify it.
mcp_execute_ability 'miriamschwab/patch-post-content' "$(jq -cn --argjson id "$TEST_POST_ID" '{
    post_id: $id, find: "Created over MCP", replace: "Modified over MCP"
}')"
patched="$(mcp_payload)"
assert_eq 'patch-post-content reports success' 'true' "$(jq -r '.success // false' <<<"$patched")"
assert_eq 'patch-post-content made exactly one replacement' '1' \
    "$(jq -r '.data.replacements_made // empty' <<<"$patched")"

# Verify the modification independently of the tool that made it.
modified_content="$(wp_cli post get "$TEST_POST_ID" --field=content 2>/dev/null | tr -d '\r' || true)"
assert_contains 'the modification is present in the database' "$modified_content" 'Modified over MCP'
assert_not_contains 'the original text is gone' "$modified_content" 'Created over MCP'

# A patch whose find string is absent must fail rather than silently succeed.
mcp_execute_ability 'miriamschwab/patch-post-content' "$(jq -cn --argjson id "$TEST_POST_ID" '{
    post_id: $id, find: "this string is not in the content", replace: "x"
}')"
assert_eq 'patch-post-content fails when the find string is absent' 'true' "$(mcp_is_error)"
assert_contains 'the failure explains why' "$MCP_LAST_BODY" 'find string was not found'

# Trash it.
mcp_execute_ability 'miriamschwab/trash-post' "$(jq -cn --argjson id "$TEST_POST_ID" '{post_id:$id}')"
trashed="$(mcp_payload)"
assert_eq 'trash-post reports success' 'true' "$(jq -r '.success // false' <<<"$trashed")"
assert_eq 'trash-post reports the page as trashed' 'trashed' \
    "$(jq -r '.data.status // empty' <<<"$trashed")"

assert_eq 'the database confirms the page is in the trash' 'trash' \
    "$(wp_cli post get "$TEST_POST_ID" --field=post_status 2>/dev/null | tr -d '\r' || true)"

mcp_execute_ability 'miriamschwab/get-pages' \
    "$(jq -cn --arg s "$TEST_TITLE" '{search:$s,status:"any"}')"
assert_eq 'the trashed page no longer appears in get-pages' '' \
    "$(mcp_payload | jq -r --argjson id "$TEST_POST_ID" \
        '(.data // [])[] | select(.ID == $id) | .ID | tostring' | head -1)"

# ===========================================================================
suite 'Layer 3 — session termination'
# ===========================================================================

terminated_session="$MCP_SESSION_ID"
mcp_terminate
after="$(curl -sS -X POST "$(mcp_endpoint)" \
    --user "$(mcp_creds)" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -H "Mcp-Session-Id: $terminated_session" \
    -d '{"jsonrpc":"2.0","id":500,"method":"tools/list","params":{}}' 2>/dev/null || true)"
assert_contains 'a terminated session is no longer accepted' "$after" 'error'

test_summary
