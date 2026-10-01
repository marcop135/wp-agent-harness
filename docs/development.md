# Development

## Requirements

| Tool | Why | Notes |
|------|-----|-------|
| Docker + Compose v2 | runs WordPress and MariaDB | Docker Desktop on macOS/Windows, Docker Engine on Linux |
| Git | clone | |
| Bash | the `./bin` commands | Git Bash on Windows, the system shell elsewhere |
| curl | health and MCP checks | ships with Git Bash and macOS |
| Claude Code | MCP registration and test layer 4 | optional for layers 0–3 |
| jq | the test suite only | `brew install jq` · `apt install jq` · `winget install jqlang.jq` |

## Daily loop

```bash
./bin/start                  # bring the stack up
cd . && claude               # work through Claude Code
./bin/status                 # when something looks wrong
./bin/test --skip-claude     # before committing a change to this repository
./bin/stop                   # done for the day
```

`./bin/setup` is safe at any time: it reconciles the running site with `.env`
and never destroys content.

## Commands

| Command | What it does |
|---------|--------------|
| `./bin/setup` | Validate prerequisites, create `.env`, build, start, install and configure WordPress, issue the Application Password, verify the stack. Idempotent. |
| `./bin/start` | Start the Docker services and wait for health. |
| `./bin/stop` | Stop the services. Volumes and content survive. |
| `./bin/reset` | **Destructive.** Remove containers, both volumes and the stored credential, then rebuild. Asks for confirmation; `--yes` skips it, `--no-setup` destroys without rebuilding. Run `./bin/connect` afterwards; the Application Password is new. |
| `./bin/status` | Container health, WordPress health, ability registration, MCP endpoint health, Claude Code registration. |
| `./bin/logs` | Docker logs. `./bin/logs -f wordpress` follows one service; `./bin/logs --debug` shows WordPress's own PHP debug log. |
| `./bin/test` | The test suite. `--skip-claude` skips the layer that costs model turns; a file name (`repo`, `smoke`, `integration`, `claude-code`) runs one. |
| `./bin/connect` | Claude Code: register MCP. `--remove` unregisters. `--print` shows URL, header, and `WORDPRESS_MCP_BASIC_AUTH` export (no Claude required; used by Codex/Cursor). |
| `./bin/wp` | WP-CLI inside the container, e.g. `./bin/wp ability list`. |

`make help` lists the same set as Make targets.

## URLs

| | |
|---|---|
| Site | `http://localhost:8080` |
| Admin | `http://localhost:8080/wp-admin/` |
| REST API | `http://localhost:8080/wp-json/` |
| MCP endpoint | `http://localhost:8080/wp-json/mcp/mcp-adapter-default-server` |

All bound to `127.0.0.1`. Change the port with `WP_PORT` in `.env`, then
`./bin/start`. No reinstall is needed.

## Reuse as a template

**Use this template** on GitHub, then change three values in `.env`:

```bash
COMPOSE_PROJECT_NAME=my-project   # Docker project and volume prefix
WP_PORT=8081                      # and DB_PORT, if 3307 is taken
WP_SITE_TITLE=My Project
```

Then `./bin/setup`. Claude Code: `./bin/connect && claude`. Codex: export from
`./bin/connect --print`, then `codex` ([codex.md](codex.md)). Cursor: same skills
under `.cursor/skills/`; register MCP from `--print`. Detail:
[claude-code.md](claude-code.md).

## Testing

```bash
./bin/test                 # everything
./bin/test --skip-claude   # all but layer 4, no model turns
./bin/test repo            # repository integrity only, no Docker needed
./bin/test smoke           # one file only
```

| Layer | File | Verifies |
|-------|------|----------|
| 0 Repository | `tests/repo.sh` | `.gitignore`, no secrets tracked, scripts parse, documented files tracked, README pins match `.env.example`, loopback bindings |
| 1 Infrastructure | `tests/smoke.sh` | Compose config, services, health, loopback ports, `.env` |
| 2 WordPress / Abilities | `tests/smoke.sh` | WordPress ≥ 6.9, plugins at pinned versions, abilities registered, `wp ability run` |
| 3 MCP protocol | `tests/integration.sh` | Auth, session lifecycle, tool discovery and execution, content cycle |
| 4 Claude Code | `tests/claude-code.sh` | Headless `claude -p` checked against the database with WP-CLI |

Tests create only uniquely named content and delete it again.

## Reaching WordPress directly

```bash
./bin/wp plugin list
./bin/wp post list --post_type=page
./bin/wp option get permalink_structure
./bin/wp db query 'SELECT COUNT(*) FROM wp_posts;'
```

`./bin/wp` is WP-CLI inside the container, running as `www-data`. Everything
WP-CLI can do is available, including `wp db export` for a throwaway snapshot:

```bash
./bin/wp db export - > tmp/snapshot.sql       # tmp/ is git-ignored
docker compose exec -T wordpress wp db import - < tmp/snapshot.sql
```

A shell in the container:

```bash
docker compose exec wordpress bash
```

## The abilities, without MCP

This is the diagnostic path that skips MCP entirely: if something works here
and not through Claude Code, the problem is in the transport or the credential.

```bash
./bin/wp ability list
./bin/wp ability list --namespace=miriamschwab --fields=name,label
./bin/wp ability get miriamschwab/create-post
./bin/wp ability can-run miriamschwab/create-post --user=admin
./bin/wp ability validate miriamschwab/create-post --input='{"title":"Test"}'
./bin/wp ability run core/get-site-info --user=admin
./bin/wp ability category list
```

`wp ability run` takes `--input=<json>`, `--input=-` for stdin, or individual
`--<field>=<value>` flags for simple inputs.

**Tools → WP Abilities** in wp-admin shows the same list with the MCP-public
flag and the input schema per ability, and flags what a plugin update added or
removed since your last visit.

## Speaking MCP by hand

Useful when you want to see exactly what Claude Code sees.

```bash
ENDPOINT=http://localhost:8080/wp-json/mcp/mcp-adapter-default-server
CREDS="admin:$(cat .secrets/application-password)"

# 1. initialize, and keep the session ID
SESSION=$(curl -sS -D - -o /dev/null -X POST "$ENDPOINT" --user "$CREDS" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}' \
  | grep -i '^mcp-session-id:' | cut -d' ' -f2 | tr -d '\r')

# 2. announce readiness
curl -sS -X POST "$ENDPOINT" --user "$CREDS" \
  -H 'Content-Type: application/json' -H "Mcp-Session-Id: $SESSION" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'

# 3. list the three meta-tools
curl -sS -X POST "$ENDPOINT" --user "$CREDS" \
  -H 'Content-Type: application/json' -H "Mcp-Session-Id: $SESSION" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | jq

# 4. execute an ability
curl -sS -X POST "$ENDPOINT" --user "$CREDS" \
  -H 'Content-Type: application/json' -H "Mcp-Session-Id: $SESSION" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"mcp-adapter-execute-ability","arguments":{"ability_name":"miriamschwab/get-plugins","parameters":{}}}}' | jq

# 5. end the session
curl -sS -X DELETE "$ENDPOINT" --user "$CREDS" -H "Mcp-Session-Id: $SESSION"
```

`tests/lib.sh` wraps exactly this in about twenty lines.

The STDIO transport skips HTTP and authentication altogether, which isolates
whether a failure is in the adapter or in the request:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | ./bin/wp mcp-adapter serve --user=admin --server=mcp-adapter-default-server
./bin/wp mcp-adapter list
```

## Working on plugin or theme source

The whole WordPress install lives in the `wp_data` volume, which keeps the
repository free of generated files and avoids file-ownership and line-ending
problems on Windows and macOS. To edit your own plugin or theme from the host,
bind-mount just that directory with a Compose override:

```yaml
# docker-compose.override.yml   (git-ignored)
services:
  wordpress:
    volumes:
      - ./src/my-plugin:/var/www/html/wp-content/plugins/my-plugin
```

```bash
mkdir -p src/my-plugin
./bin/start
./bin/wp plugin activate my-plugin
```

Compose merges the override automatically. Nothing else changes, and
`./bin/reset` still works : the bind-mounted directory is yours, not the
volume's.

For one-off file moves:

```bash
docker compose cp wordpress:/var/www/html/wp-content/themes/twentytwentyfive ./tmp/
docker compose cp ./tmp/patched-file.php wordpress:/var/www/html/wp-content/themes/twentytwentyfive/
```

## Debugging PHP

`WP_DEBUG` and `WP_DEBUG_LOG` are on; `WP_DEBUG_DISPLAY` is off, so notices go to
the log rather than corrupting REST responses.

```bash
./bin/logs --debug          # wp-content/debug.log
./bin/logs --debug 500      # last 500 lines
./bin/logs -f wordpress     # Apache and PHP-FPM output
```

The MCP Adapter logs through `ErrorLogMcpErrorHandler`, so adapter-level errors
land in the same debug log.

## Configuration

Every setting is a variable in `.env`, which is git-ignored. `.env.example` is
the tracked template; `./bin/setup` copies it and replaces every `CHANGE_ME`
with a freshly generated random secret. The ones you are most likely to change:

| Variable | Default | Purpose |
|----------|---------|---------|
| `WP_PORT` | `8080` | host port for WordPress, bound to `127.0.0.1` |
| `DB_PORT` | `3307` | host port for MariaDB, bound to `127.0.0.1` |
| `WP_THEME` | `twentytwentyfive` | installed and activated by setup |
| `WP_SITE_TITLE` | `WP Agent Harness` | site title |
| `WP_ADMIN_USER` | `admin` | development administrator login |
| `WP_ADMIN_PASSWORD` | generated | **wp-admin** password, not the MCP credential |
| `MCP_SERVER_NAME` | `wordpress` | name Claude Code registers the server under |
| `COMPOSE_PROJECT_NAME` | `wp-agent-harness` | Docker Compose project and volume prefix |

Image tags, plugin pins, and the Application Password label are documented
inline in [`.env.example`](../.env.example). Current pins are listed under
[Versions](#versions).

## Versions

| Component | Version | Source |
|-----------|---------|--------|
| WordPress | 7.1.2 | `wordpress:7.1.2-php8.3-apache` |
| PHP | 8.3 | same image |
| Apache | 2.4 | same image |
| MariaDB | 11.8.9 | `mariadb:11.8.9` |
| WP-CLI | 2.12.0 | GitHub release phar, SHA-512 verified |
| `wp-cli/ability-command` | 1.0.2 | GitHub release tarball |
| MCP Adapter | 0.6.1 | GitHub release ZIP |
| MS WordPress Abilities | 1.12.0 | GitHub release ZIP |
| Twenty Twenty-Five | 1.5 | wordpress.org |
| MCP protocol | 2025-11-25 | negotiated; the adapter also supports 2025-06-18 and 2024-11-05 |

Pins live in [`.env.example`](../.env.example). How to bump them:
[Updating dependencies](#updating-dependencies).

## Dependencies

Nothing here tracks a moving upstream branch. Versions are pinned in `.env` /
[`.env.example`](../.env.example). How to bump them is covered under
[Updating dependencies](#updating-dependencies).

| Component | Role | How it gets here | Licence | Pin |
|-----------|------|------------------|---------|-----|
| **MCP Adapter** | Exposes abilities over MCP | WordPress plugin, GitHub release ZIP at `./bin/setup` | GPL-2.0-or-later | `MCP_ADAPTER_VERSION` |
| **MS WordPress Abilities** | Registers site-management abilities | WordPress plugin, GitHub release ZIP at `./bin/setup` | GPL-2.0-or-later | `MS_WP_ABILITIES_VERSION` |
| **WP-CLI** | CLI inside the container | Phar in the Docker image build | MIT | `WP_CLI_VERSION` |
| **wp-cli/ability-command** | `wp ability` diagnostic path (not MCP) | Tarball in the Docker image build | MIT | `WP_CLI_ABILITY_COMMAND_VERSION` |
| **WordPress** | The site | Official Docker image | GPL-2.0-or-later | `WORDPRESS_IMAGE` |
| **MariaDB** | Database | Official Docker image | GPL-2.0-or-later | `MARIADB_IMAGE` |
| **Twenty Twenty-Five** | Default theme | wordpress.org via setup | GPL-2.0-or-later | `WP_THEME` |
| **WordPress agent skills** | Agent procedures (blocks, themes, Abilities, …) | **Vendored** under `.claude/skills/` and `.cursor/skills/` | GPL-2.0-or-later | manual refresh (see below) |

Only **two** WordPress plugins are installed at runtime. `ability-command` is a
WP-CLI package in the image, not a plugin. Agent skills are the only upstream
source tree committed into this git repository.

## Updating dependencies

Every version is a variable in `.env`, mirrored in `.env.example` so the next
clone inherits it. Nothing follows a moving branch.

| Variable | Source | Update by |
|----------|--------|-----------|
| `MCP_ADAPTER_VERSION` | GitHub release ZIP | `gh release list --repo WordPress/mcp-adapter` |
| `MS_WP_ABILITIES_VERSION` | GitHub release ZIP | `gh release list --repo miriamschwab/ms-wp-abilities` |
| `WORDPRESS_IMAGE` | Docker Hub | `docker run --rm wordpress:7.1-php8.3-apache wp core version` |
| `MARIADB_IMAGE` | Docker Hub | the MariaDB LTS line |
| `WP_CLI_VERSION` | GitHub release phar | `gh release list --repo wp-cli/wp-cli` |
| `WP_CLI_ABILITY_COMMAND_VERSION` | GitHub release tarball | `gh release list --repo wp-cli/ability-command` |
| `WP_THEME` | wordpress.org | `./bin/wp theme update twentytwentyfive` |

### Runtime plugins and image pins

```bash
# 1. edit both files so a fresh clone gets the same version
$EDITOR .env .env.example

# 2. reconcile the running site
./bin/setup

# 3. prove it still works
./bin/test --skip-claude
./bin/test claude-code
```

`wp-provision` compares the installed plugin version against the pin and
reinstalls in place when they differ, so a plugin bump needs no reset. Image and
WP-CLI changes are picked up by the rebuild `./bin/setup` runs, but WordPress core
lives in the `wp_data` volume, so a `WORDPRESS_IMAGE` bump also needs
`./bin/wp core update --version=<x.y.z>` (or `./bin/reset`). A **MariaDB major
version** change needs `./bin/reset`, because the data directory format changes.

Before pinning a new upstream version, check its requirements. Both plugins
currently need WordPress 6.9+ and PHP 7.4+, and the ability names this repository
asserts in `tests/smoke.sh` come from the pinned MS WP Abilities release. If
upstream renames one, that test fails, which is the point.

### Agent skills (vendored)

Skills are not version variables in `.env`. They are committed trees under
`.claude/skills/` and `.cursor/skills/`. Refresh from upstream deliberately,
keep the curated list, and do not install Playground or `@wordpress/env` skills
(this stack uses Docker Compose + MCP). See
[docs/claude-code.md](claude-code.md#wordpress-agent-skills).

```bash
npx skills add WordPress/agent-skills \
  --skill wordpress-router \
  --skill wp-project-triage \
  --skill wp-block-development \
  --skill wp-block-themes \
  --skill wp-patterns \
  --skill wp-plugin-development \
  --skill wp-rest-api \
  --skill wp-wpcli-and-ops \
  --skill wp-abilities-api \
  --skill wp-abilities-audit \
  --skill wp-abilities-verify
```

Commit the updated trees for both `.claude/skills/` and `.cursor/skills/` so the
two agents stay in sync.

## Changing this repository

The checks to run before proposing a change, and the conventions the scripts
follow, are in [CONTRIBUTING.md](../CONTRIBUTING.md).
