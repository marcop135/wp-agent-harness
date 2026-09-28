#!/usr/bin/env bash
#
# smoke.sh — test layers 1 and 2.
#
#   Layer 1  infrastructure: compose config, services, health, ports, env
#   Layer 2  WordPress and the Abilities API: versions, theme, plugins,
#            ability registration, `wp ability` as an MCP-independent path
#
# Read-only. Creates no content.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_docker
require_env

# ===========================================================================
suite 'Layer 1 — infrastructure'
# ===========================================================================

assert_ok 'docker compose configuration is valid' dc config --quiet

for var in COMPOSE_PROJECT_NAME WP_PORT DB_PORT WORDPRESS_IMAGE MARIADB_IMAGE \
           WP_CLI_VERSION WP_CLI_ABILITY_COMMAND_VERSION MCP_ADAPTER_VERSION \
           MS_WP_ABILITIES_VERSION WP_THEME WP_ADMIN_USER WP_ADMIN_PASSWORD \
           WP_ADMIN_EMAIL MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD \
           MYSQL_ROOT_PASSWORD MCP_APP_PASSWORD_NAME MCP_SERVER_NAME; do
    if [[ -n "$(env_get "$var")" ]]; then
        _record_pass ".env defines $var"
    else
        _record_fail ".env defines $var" 'missing or empty'
    fi
done

assert_fails '.env has no CHANGE_ME placeholders left' \
    grep -qE '^[A-Z_]+=CHANGE_ME[[:space:]]*$' "$ENV_FILE"

assert_ok 'db container is running' container_running db
assert_ok 'wordpress container is running' container_running wordpress

db_health="$(docker inspect -f '{{.State.Health.Status}}' "$(dc ps -q db)" 2>/dev/null || echo unknown)"
assert_eq 'db container is healthy' 'healthy' "$db_health"

wp_health="$(docker inspect -f '{{.State.Health.Status}}' "$(dc ps -q wordpress)" 2>/dev/null || echo unknown)"
assert_eq 'wordpress container is healthy' 'healthy' "$wp_health"

assert_ok 'database accepts queries' wp_cli db check --quiet

wp_binding="$(dc port wordpress 80 2>/dev/null | tr -d '\r' || true)"
assert_contains 'WordPress port is bound to loopback only' "$wp_binding" '127.0.0.1:'
assert_contains 'WordPress port matches WP_PORT' "$wp_binding" ":$(env_get WP_PORT 8080)"

db_binding="$(dc port db 3306 2>/dev/null | tr -d '\r' || true)"
assert_contains 'database port is bound to loopback only' "$db_binding" '127.0.0.1:'

assert_eq 'WordPress front page responds on the host port' '200' \
    "$(http_status "$(site_url)/")"

assert_eq 'REST API index responds (pretty permalinks work)' '200' \
    "$(http_status "$(site_url)/wp-json/")"

# ===========================================================================
suite 'Layer 2 — WordPress and the Abilities API'
# ===========================================================================

wp_version="$(wp_cli core version 2>/dev/null | tr -d '\r' || true)"
assert_ok 'WordPress is installed' wp_cli core is-installed
abilities_api="$(wp_cli eval 'echo version_compare( get_bloginfo( "version" ), "6.9", ">=" ) ? "yes" : "no";' 2>/dev/null | tr -d '\r' || true)"
assert_eq "WordPress $wp_version satisfies the 6.9+ Abilities API requirement" 'yes' "$abilities_api"

php_version="$(wpx php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;' 2>/dev/null | tr -d '\r' || true)"
php_ok="$(wpx php -r 'echo version_compare( PHP_VERSION, "7.4", ">=" ) ? "yes" : "no";' 2>/dev/null | tr -d '\r' || true)"
assert_eq "PHP $php_version satisfies the 7.4+ requirement of both plugins" 'yes' "$php_ok"

want_theme="$(env_get WP_THEME twentytwentyfive)"
active_theme="$(wp_cli theme list --status=active --field=name 2>/dev/null | tr -d '\r' || true)"
assert_eq "$want_theme is the active theme" "$want_theme" "$active_theme"

check_plugin() {
    local slug="$1" want="$2"
    if wp_cli plugin is-installed "$slug" >/dev/null 2>&1; then
        _record_pass "$slug is installed"
    else
        _record_fail "$slug is installed" 'not found'
        return 0
    fi
    assert_ok "$slug is active" wp_cli plugin is-active "$slug"
    assert_eq "$slug version matches .env" "$want" \
        "$(wp_cli plugin get "$slug" --field=version 2>/dev/null | tr -d '\r' || true)"
}

check_plugin mcp-adapter "$(env_get MCP_ADAPTER_VERSION)"
check_plugin ms-wp-abilities "$(env_get MS_WP_ABILITIES_VERSION)"

installed_plugins="$(wp_cli plugin list --field=name 2>/dev/null | tr -d '\r' | sort | tr '\n' ' ' || true)"
assert_eq 'exactly the two toolkit plugins are installed' \
    'mcp-adapter ms-wp-abilities ' "$installed_plugins"

# --- Abilities API, reached through WP-CLI rather than MCP ------------------
assert_ok 'wp_register_ability() exists in this WordPress build' \
    wp_cli eval 'if ( ! function_exists( "wp_register_ability" ) ) { exit( 1 ); }'

assert_ok 'wp ability is available in the container' wp_cli ability list --format=count

ability_total="$(wp_cli ability list --format=count 2>/dev/null | tr -d '\r' || echo 0)"
assert_ge 'abilities are registered' "$ability_total" 25

registered="$(wp_cli ability list --field=name 2>/dev/null | tr -d '\r' || true)"

# Names read from the pinned MS WP Abilities release, not from memory. A rename
# upstream must fail here rather than silently change what Claude Code can do.
for ability in \
    miriamschwab/get-posts \
    miriamschwab/get-pages \
    miriamschwab/get-post-types \
    miriamschwab/create-post \
    miriamschwab/preview-post-update \
    miriamschwab/apply-post-update \
    miriamschwab/patch-post-content \
    miriamschwab/trash-post \
    miriamschwab/get-media \
    miriamschwab/update-media-meta \
    miriamschwab/get-plugins \
    miriamschwab/get-themes \
    miriamschwab/get-site-settings \
    miriamschwab/rest-get \
    miriamschwab/rest-write \
    core/get-site-info \
    core/get-user-info \
    core/get-environment-info; do
    if grep -qx "$ability" <<<"$registered"; then
        _record_pass "ability registered: $ability"
    else
        _record_fail "ability registered: $ability" 'not in `wp ability list`'
    fi
done

assert_ok 'the admin user may run core/get-site-info' \
    wp_cli ability can-run core/get-site-info --user="$(env_get WP_ADMIN_USER admin)"

site_info="$(wp_cli ability run core/get-site-info --user="$(env_get WP_ADMIN_USER admin)" --format=json 2>/dev/null | tr -d '\r' || true)"
assert_contains 'wp ability run core/get-site-info returns the site URL' \
    "$site_info" "localhost:$(env_get WP_PORT 8080)"

# --- Application Password --------------------------------------------------
assert_ok 'WordPress accepts Application Password authentication' \
    wpx wp-app-password available
assert_ok 'the Claude Code Application Password exists in WordPress' \
    wpx wp-app-password exists
assert_ok 'the Application Password is stored outside Git' test -s "$APP_PASSWORD_FILE"

test_summary
