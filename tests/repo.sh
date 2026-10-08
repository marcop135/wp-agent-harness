#!/usr/bin/env bash
#
# repo.sh — repository integrity. No Docker, no WordPress, no network.
#
# Checks that nothing secret is tracked, that .gitignore keeps it that way,
# that every shell script parses, that the Compose file is valid, and that the
# versions in .env.example and docs/development.md have not drifted apart.
#
# Runs locally (./bin/test repo) and in CI.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

cd "$REPO_ROOT" || die "Cannot enter $REPO_ROOT"

# ===========================================================================
suite 'Repository — .gitignore'
# ===========================================================================

for pattern in '.env' '.secrets/' '*.sql' '.mcp.json' '.claude/settings.local.json' \
               '/wp-content/' 'logs/' 'node_modules/' 'vendor/' '.DS_Store'; do
    if grep -qxF "$pattern" .gitignore; then
        _record_pass ".gitignore excludes $pattern"
    else
        _record_fail ".gitignore excludes $pattern" 'pattern not found'
    fi
done

assert_ok '.env.example is exempted from the .env* rule' \
    grep -qxF '!.env.example' .gitignore

# ===========================================================================
suite 'Repository — nothing secret is tracked'
# ===========================================================================

tracked="$(git ls-files)"

for forbidden in '^\.env$' '^\.secrets/' '\.sql$' '\.sql\.gz$' '^\.mcp\.json$' \
                 '^\.claude/settings\.local\.json$' '^wp-config\.php$' \
                 '^wp-content/' '\.pem$' '\.key$' '\.p12$'; do
    if grep -qE "$forbidden" <<<"$tracked"; then
        _record_fail "no tracked file matches $forbidden" \
            "$(grep -E "$forbidden" <<<"$tracked" | head -5)"
    else
        _record_pass "no tracked file matches $forbidden"
    fi
done

# The generated WordPress install and uploads must never appear.
for forbidden in 'wp-admin/' 'wp-includes/' 'uploads/'; do
    if grep -qF "$forbidden" <<<"$tracked"; then
        _record_fail "no tracked path contains $forbidden" \
            "$(grep -F "$forbidden" <<<"$tracked" | head -5)"
    else
        _record_pass "no tracked path contains $forbidden"
    fi
done

# ===========================================================================
suite 'Repository — no credential material in tracked content'
# ===========================================================================

# Scan tracked text files only, and skip this file — it contains the patterns.
scan_files() {
    git ls-files -z \
        | while IFS= read -r -d '' f; do
            [[ "$f" == 'tests/repo.sh' ]] && continue
            [[ -f "$f" ]] || continue
            grep -Iq . "$f" 2>/dev/null && printf '%s\n' "$f"
        done
}

readarray -t TEXT_FILES < <(scan_files)

scan_for() {
    local label="$1" pattern="$2" hits
    hits="$(grep -nEI "$pattern" "${TEXT_FILES[@]}" 2>/dev/null | head -5 || true)"
    if [[ -z "$hits" ]]; then
        _record_pass "no $label"
    else
        _record_fail "no $label" "$hits"
    fi
}

scan_for 'PEM private key'          '-----BEGIN [A-Z ]*PRIVATE KEY-----'
scan_for 'AWS access key id'        'AKIA[0-9A-Z]{16}'
scan_for 'GitHub token'             'gh[pousr]_[A-Za-z0-9]{36}'
scan_for 'Anthropic API key'        'sk-ant-[A-Za-z0-9_-]{20,}'
scan_for 'hard-coded Basic auth header' 'Authorization:[[:space:]]*Basic[[:space:]]+[A-Za-z0-9+/]{16,}={0,2}'
# A WordPress Application Password is 24 characters, shown in 6 chunks of 4.
scan_for 'WordPress Application Password' '\b([A-Za-z0-9]{4} ){5}[A-Za-z0-9]{4}\b'

# ===========================================================================
suite 'Repository — .env.example holds no real secrets'
# ===========================================================================

for var in WP_ADMIN_PASSWORD MYSQL_PASSWORD MYSQL_ROOT_PASSWORD; do
    assert_eq "$var in .env.example is a CHANGE_ME placeholder" 'CHANGE_ME' \
        "$(grep -E "^${var}=" .env.example | cut -d= -f2- | tr -d '\r')"
done

# ===========================================================================
suite 'Repository — shell scripts'
# ===========================================================================

for script in bin/setup bin/start bin/stop bin/reset bin/status bin/logs \
              bin/test bin/connect bin/wp bin/lib.sh \
              tests/lib.sh tests/smoke.sh tests/integration.sh \
              tests/claude-code.sh tests/repo.sh \
              docker/wordpress/bin/wp docker/wordpress/bin/wp-provision \
              docker/wordpress/bin/wp-app-password; do
    if [[ -f "$script" ]]; then
        assert_ok "$script parses" bash -n "$script"
    else
        _record_fail "$script parses" 'file is missing'
    fi
done

for script in bin/setup bin/start bin/stop bin/reset bin/status bin/logs \
              bin/test bin/connect bin/wp; do
    if [[ "$(git ls-files -s "$script" | cut -d' ' -f1)" == '100755' ]]; then
        _record_pass "$script is tracked as executable"
    else
        _record_fail "$script is tracked as executable" \
            "mode $(git ls-files -s "$script" | cut -d' ' -f1); fix with git update-index --chmod=+x $script"
    fi
done

# ===========================================================================
suite 'Repository — documented files exist'
# ===========================================================================

for f in README.md CLAUDE.md AGENTS.md llms.txt CHANGELOG.md LICENSE NOTICE Makefile docker-compose.yml \
         .env.example .gitignore .gitattributes \
         CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md \
         .github/workflows/test.yml .github/dependabot.yml \
         .github/CODEOWNERS .github/PULL_REQUEST_TEMPLATE.md \
         .github/ISSUE_TEMPLATE/config.yml .github/ISSUE_TEMPLATE/1-bug.yml \
         .github/ISSUE_TEMPLATE/2-feature.yml .github/ISSUE_TEMPLATE/3-question.yml \
         .cursor/AGENTS.md .codex/config.toml \
         docs/AGENTS.md docs/ai-skills.md docs/architecture.md docs/claude-code.md docs/codex.md docs/development.md \
         docs/remote-site.md docs/security.md docs/troubleshooting.md \
         docs/agents/README.md docs/agents/agent-contract.md docs/agents/runtime-policy.md \
         .github/brand/README.md .github/brand/brand.config.json .github/brand/render.mjs \
         .github/brand/readme-light.svg .github/brand/readme-light.png \
         .github/brand/readme-dark.svg .github/brand/readme-dark.png \
         .github/brand/social.svg .github/brand/social.png \
         .github/brand/og.svg .github/brand/og.png \
         examples/README.md examples/inspect-site.md examples/create-content.md \
         examples/modify-content.md examples/media.md examples/theme.md \
         examples/plugins.md examples/site-development.md \
         docker/wordpress/Dockerfile docker/wordpress/wp-cli.yml \
         docker/wordpress/apache-wordpress.conf \
         docker/wordpress/ability-command-autoload.php \
         docker/wordpress/bin/wp docker/wordpress/bin/wp-provision \
         docker/wordpress/bin/wp-app-password; do
    # On disk and in the index: an over-broad .gitignore rule would otherwise
    # silently drop tracked infrastructure.
    if [[ ! -f "$f" ]]; then
        _record_fail "$f is tracked" 'file is missing'
    elif grep -qxF "$f" <<<"$tracked"; then
        _record_pass "$f is tracked"
    else
        _record_fail "$f is tracked" "$(git check-ignore -v "$f" 2>/dev/null || echo 'not in the index')"
    fi
done

# ===========================================================================
suite 'Repository — versions agree between .env.example and docs/development.md'
# ===========================================================================

versions_doc="$(cat docs/development.md)"
for var in MCP_ADAPTER_VERSION MS_WP_ABILITIES_VERSION WP_CLI_VERSION \
           WP_CLI_ABILITY_COMMAND_VERSION WORDPRESS_IMAGE MARIADB_IMAGE; do
    value="$(grep -E "^${var}=" .env.example | cut -d= -f2- | tr -d '\r')"
    if [[ -z "$value" ]]; then
        _record_fail "$var is set in .env.example" 'missing'
    else
        assert_contains "docs/development.md documents $var=$value" "$versions_doc" "$value"
    fi
done

# ===========================================================================
suite 'Repository — Docker Compose'
# ===========================================================================

if have docker && docker info >/dev/null 2>&1 && [[ -f "$ENV_FILE" ]]; then
    assert_ok 'docker-compose.yml is valid' dc config --quiet
    assert_ok 'Compose ports and network_mode stay loopback-safe' check_loopback_bindings
    binding="$(dc config --format json 2>/dev/null \
        | jq -r '.services.wordpress.ports[0].host_ip // empty' || true)"
    assert_eq 'the WordPress port binds to loopback' '127.0.0.1' "$binding"
    binding="$(dc config --format json 2>/dev/null \
        | jq -r '.services.db.ports[0].host_ip // empty' || true)"
    assert_eq 'the database port binds to loopback' '127.0.0.1' "$binding"
    host_modes="$(dc config --format json 2>/dev/null \
        | jq -r '[.services[]? | select((.network_mode // "") == "host") | .] | length' || true)"
    assert_eq 'no service uses network_mode: host' '0' "$host_modes"
else
    note 'Docker or .env unavailable — skipping Compose validation'
fi

# Guard against the bindings being widened in the source file itself.
assert_fails 'no service publishes on 0.0.0.0' \
    grep -qE '^\s*-\s*["'\'']?0\.0\.0\.0:' docker-compose.yml
assert_fails 'no service sets network_mode: host in the base file' \
    grep -qEi '^\s*network_mode:\s*["'\'']?host["'\'']?\s*$' docker-compose.yml

# ===========================================================================
suite 'Repository — secret file modes (when the FS enforces them)'
# ===========================================================================

# Probe whether chmod sticks on this repo mount (WSL /mnt/c often does not).
mode_probe="$REPO_ROOT/.mode-probe.$$"
: >"$mode_probe"
chmod 600 "$mode_probe" 2>/dev/null || true
probe_mode="$(stat -c '%a' "$mode_probe" 2>/dev/null || stat -f '%OLp' "$mode_probe" 2>/dev/null || echo '')"
rm -f "$mode_probe"
probe_mode="${probe_mode#0}"

if [[ "$probe_mode" != '600' ]]; then
    note 'filesystem does not enforce Unix modes — skipping secret mode asserts'
else
    if [[ -d "$REPO_ROOT/.secrets" ]]; then
        dir_mode="$(stat -c '%a' "$REPO_ROOT/.secrets" 2>/dev/null || stat -f '%OLp' "$REPO_ROOT/.secrets")"
        dir_mode="${dir_mode#0}"
        if [[ "$dir_mode" == '700' ]]; then
            _record_pass '.secrets is mode 700'
        else
            _record_fail '.secrets is mode 700' "mode=$dir_mode"
        fi
    else
        note '.secrets/ absent — run ./bin/setup to create it'
    fi
    if [[ -f "$REPO_ROOT/.env" ]]; then
        env_mode="$(stat -c '%a' "$REPO_ROOT/.env" 2>/dev/null || stat -f '%OLp' "$REPO_ROOT/.env")"
        env_mode="${env_mode#0}"
        if [[ "$env_mode" == '600' ]]; then
            _record_pass '.env is mode 600'
        else
            _record_fail '.env is mode 600' "mode=$env_mode"
        fi
    fi
    if [[ -f "$REPO_ROOT/.secrets/application-password" ]]; then
        pw_mode="$(stat -c '%a' "$REPO_ROOT/.secrets/application-password" 2>/dev/null \
            || stat -f '%OLp' "$REPO_ROOT/.secrets/application-password")"
        pw_mode="${pw_mode#0}"
        if [[ "$pw_mode" == '600' ]]; then
            _record_pass 'application-password is mode 600'
        else
            _record_fail 'application-password is mode 600' "mode=$pw_mode"
        fi
    fi
fi

test_summary
