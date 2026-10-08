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
claude                       # work through Claude Code, from the repo root
./bin/status                 # when something looks wrong
./bin/test --skip-claude     # before committing a change to this repository
./bin/stop                   # done for the day
```

`./bin/setup` is safe to re-run at any time. It reconciles the running site
with `.env` and never destroys content.

## Commands

| Command | What it does |
|---------|--------------|
| `./bin/setup` | Check prerequisites, create `.env`, build, start, install and configure WordPress, issue the Application Password, verify. Idempotent. |
| `./bin/start` | Start the services and wait for health. |
| `./bin/stop` | Stop the services. Volumes and content survive. |
| `./bin/reset` | **Destructive.** Remove containers, both volumes and the stored credential, then rebuild. Asks first; `--yes` skips the prompt, `--no-setup` skips the rebuild. Run `./bin/connect` afterwards: the Application Password is new. |
| `./bin/status` | Health of containers, WordPress, abilities, the MCP endpoint and the Claude Code registration. |
| `./bin/logs` | Docker logs. `-f wordpress` follows one service; `--debug` shows WordPress's PHP debug log. |
| `./bin/test` | The test suite. `--skip-claude` skips layer 4 (model turns); `repo`, `smoke`, `integration` or `claude-code` runs one file. |
| `./bin/connect` | Register MCP with Claude Code. `--remove` unregisters. `--print` shows the URL, header and `WORDPRESS_MCP_BASIC_AUTH` export for Codex and Cursor (no Claude needed). |
| `./bin/wp` | WP-CLI inside the container, e.g. `./bin/wp ability list`. |

`make help` lists the same commands as Make targets.

## URLs

| | |
|---|---|
| Site | `http://localhost:8080` |
| Admin | `http://localhost:8080/wp-admin/` |
| REST API | `http://localhost:8080/wp-json/` |
| MCP endpoint | `http://localhost:8080/wp-json/mcp/mcp-adapter-default-server` |

All bound to `127.0.0.1`. To change the port, set `WP_PORT` in `.env` and run
`./bin/start`; no reinstall needed.

## Configuration

Every setting is a variable in `.env` (git-ignored). `.env.example` is the
tracked template: `./bin/setup` copies it and replaces each `CHANGE_ME` with a
random secret. The ones you are most likely to change:

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

Image tags, plugin pins and the Application Password label are documented
inline in [`.env.example`](../.env.example). Current pins: [Versions](#versions).

## Testing

```bash
./bin/test                 # everything
./bin/test --skip-claude   # all but layer 4, no model turns
./bin/test repo            # repository integrity only, no Docker needed
./bin/test smoke           # one file only
```

| Layer | File | Checks |
|-------|------|--------|
| 0 Repository | `tests/repo.sh` | `.gitignore`, no secrets tracked, scripts parse, documented files tracked, pins in this file match `.env.example`, loopback bindings |
| 1 Infrastructure | `tests/smoke.sh` | Compose config, services, health, loopback ports, `.env` |
| 2 WordPress / Abilities | `tests/smoke.sh` | WordPress ≥ 6.9, plugins at pinned versions, abilities registered, `wp ability run` |
| 3 MCP protocol | `tests/integration.sh` | Auth, session lifecycle, tool discovery and execution, content cycle |
| 4 Claude Code | `tests/claude-code.sh` | Headless `claude -p`, checked against the database with WP-CLI |

Tests create only uniquely named content and delete it again.

## Reaching WordPress directly

`./bin/wp` is WP-CLI inside the container, running as `www-data`. Anything
WP-CLI can do works:

```bash
./bin/wp plugin list
./bin/wp post list --post_type=page
./bin/wp option get permalink_structure
./bin/wp db query 'SELECT COUNT(*) FROM wp_posts;'
```

A throwaway database snapshot:

```bash
./bin/wp db export - > tmp/snapshot.sql       # tmp/ is git-ignored
docker compose exec -T wordpress wp db import - < tmp/snapshot.sql
```

A shell in the container: `docker compose exec wordpress bash`.

## The abilities, without MCP

The diagnostic path that skips MCP entirely. If something works here but not
through Claude Code, the problem is the transport or the credential.

```bash
./bin/wp ability list
./bin/wp ability list --namespace=miriamschwab --fields=name,label
./bin/wp ability get miriamschwab/create-post
./bin/wp ability can-run miriamschwab/create-post --user=admin
./bin/wp ability validate miriamschwab/create-post --input='{"title":"Test"}'
./bin/wp ability run core/get-site-info --user=admin
./bin/wp ability category list
```

`wp ability run` takes `--input=<json>`, `--input=-` for stdin, or
`--<field>=<value>` flags for simple inputs.

In wp-admin, **Tools → WP Abilities** shows the same list with the MCP-public
flag and input schema per ability, and flags what a plugin update added or
removed since your last visit.

## Speaking MCP by hand

To see exactly what Claude Code sees:

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

`tests/lib.sh` wraps the same sequence in about twenty lines.

The STDIO transport skips HTTP and authentication. Use it to tell an adapter
failure from a request failure:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | ./bin/wp mcp-adapter serve --user=admin --server=mcp-adapter-default-server
./bin/wp mcp-adapter list
```

## Working on plugin or theme source

The WordPress install lives in the `wp_data` volume. That keeps generated files
out of the repository and avoids ownership and line-ending problems on Windows
and macOS. To edit your own plugin or theme from the host, bind-mount just that
directory with a Compose override:

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

Compose merges the override automatically. `./bin/reset` still works: the
bind-mounted directory is yours, not the volume's.

For one-off file copies:

```bash
docker compose cp wordpress:/var/www/html/wp-content/themes/twentytwentyfive ./tmp/
docker compose cp ./tmp/patched-file.php wordpress:/var/www/html/wp-content/themes/twentytwentyfive/
```

## Debugging PHP

`WP_DEBUG` and `WP_DEBUG_LOG` are on. `WP_DEBUG_DISPLAY` is off, so notices go
to the log instead of corrupting REST responses.

```bash
./bin/logs --debug          # wp-content/debug.log
./bin/logs --debug 500      # last 500 lines
./bin/logs -f wordpress     # Apache and PHP output
```

The MCP Adapter logs through `ErrorLogMcpErrorHandler`, so adapter errors land
in the same debug log.

## Versions

| Component | Version | Source |
|-----------|---------|--------|
| WordPress | 7.1.2 | `wordpress:7.1.2-php8.3-apache` |
| PHP | 8.3 | same image |
| Apache | 2.4 | same image |
| MariaDB | 11.8.9 | `mariadb:11.8.9` |
| WP-CLI | 2.12.0 | GitHub release phar, SHA-512 verified |
| `wp-cli/ability-command` | 1.0.2 | GitHub release tarball, SHA-256 verified (`WP_CLI_ABILITY_COMMAND_SHA256`) |
| MCP Adapter | 0.7.0 | GitHub release ZIP, SHA-256 verified (`MCP_ADAPTER_SHA256`) |
| MS WordPress Abilities | 1.12.0 | GitHub release ZIP, SHA-256 verified (`MS_WP_ABILITIES_SHA256`) |
| Twenty Twenty-Five | 1.5 | wordpress.org |
| MCP protocol | 2025-11-25 | negotiated default; the adapter also serves 2026-07-28, and 2025-06-18 / 2024-11-05 clients still connect via the 2025-11-25 schema |

Pins live in [`.env.example`](../.env.example). To bump them, see
[Updating dependencies](#updating-dependencies).

## Dependencies

Nothing tracks a moving upstream branch; every pin is a variable in `.env` and
`.env.example`.

| Component | Role | How it gets here | Licence | Pin |
|-----------|------|------------------|---------|-----|
| **MCP Adapter** | Exposes abilities over MCP | Plugin, GitHub release ZIP at `./bin/setup` (also on [wordpress.org](https://wordpress.org/plugins/mcp-adapter/); this repo pins the GitHub ZIP) | GPL-2.0-or-later | `MCP_ADAPTER_VERSION` |
| **MS WordPress Abilities** | Registers site-management abilities | Plugin, GitHub release ZIP at `./bin/setup` | GPL-2.0-or-later | `MS_WP_ABILITIES_VERSION` |
| **WP-CLI** | CLI inside the container | Phar in the image build | MIT | `WP_CLI_VERSION` |
| **wp-cli/ability-command** | `wp ability` diagnostic path (not MCP) | Tarball in the image build | MIT | `WP_CLI_ABILITY_COMMAND_VERSION` |
| **WordPress** | The site | Official Docker image | GPL-2.0-or-later | `WORDPRESS_IMAGE` |
| **MariaDB** | Database | Official Docker image | GPL-2.0-or-later | `MARIADB_IMAGE` |
| **Twenty Twenty-Five** | Default theme | wordpress.org via setup | GPL-2.0-or-later | `WP_THEME` |
| **WordPress agent skills** | Agent procedures (blocks, themes, Abilities, …) | **Vendored** under `.claude/skills/` and `.cursor/skills/` | GPL-2.0-or-later | manual refresh (below) |

Only **two** WordPress plugins run on the site. `ability-command` is a WP-CLI
package in the image, not a plugin. The agent skills are the only upstream
source tree committed to this repository.

## Updating dependencies

| Variable | Source | Find the new version |
|----------|--------|----------------------|
| `MCP_ADAPTER_VERSION` / `MCP_ADAPTER_SHA256` | GitHub release ZIP | `gh release list --repo WordPress/mcp-adapter`; recompute the ZIP's SHA-256 |
| `MS_WP_ABILITIES_VERSION` / `MS_WP_ABILITIES_SHA256` | GitHub release ZIP | `gh release list --repo miriamschwab/ms-wp-abilities`; recompute SHA-256 |
| `WORDPRESS_IMAGE` | Docker Hub | `docker run --rm wordpress:7.1-php8.3-apache wp core version` |
| `MARIADB_IMAGE` | Docker Hub | the MariaDB LTS line |
| `WP_CLI_VERSION` | GitHub release phar | `gh release list --repo wp-cli/wp-cli` |
| `WP_CLI_ABILITY_COMMAND_VERSION` / `WP_CLI_ABILITY_COMMAND_SHA256` | GitHub release tarball | `gh release list --repo wp-cli/ability-command`; recompute SHA-256 |
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

What each kind of bump needs:

| Change | Needs |
|--------|-------|
| Plugin version | `./bin/setup` only: `wp-provision` reinstalls in place when the installed version differs from the pin |
| Image or WP-CLI | `./bin/setup` only: it rebuilds the image |
| `WORDPRESS_IMAGE` | also `./bin/wp core update --version=<x.y.z>` (or `./bin/reset`), because core lives in the `wp_data` volume |
| MariaDB major version | `./bin/reset`: the data directory format changes |

Before pinning a new upstream version, check its requirements. Both plugins
currently need WordPress 6.9+ and PHP 7.4+. The ability names asserted in
`tests/smoke.sh` come from the pinned MS WP Abilities release; if upstream
renames one, that test fails, which is the point.

### Agent skills (vendored)

Skills are not `.env` variables. They are committed trees under
`.claude/skills/` and `.cursor/skills/`. Refresh them deliberately, keep the
curated list, and do not add Playground or `@wordpress/env` skills (this stack
is Docker Compose + MCP). See
[claude-code.md](claude-code.md#wordpress-agent-skills).

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

Commit both `.claude/skills/` and `.cursor/skills/` so the two agents stay in
sync.

## Reuse as a template

Click **Use this template** on GitHub, then change three values in `.env`:

```bash
COMPOSE_PROJECT_NAME=my-project   # Docker project and volume prefix
WP_PORT=8081                      # and DB_PORT, if 3307 is taken
WP_SITE_TITLE=My Project
```

Then run `./bin/setup` and connect a client: `./bin/connect && claude` for
Claude Code, [codex.md](codex.md) for Codex, `./bin/connect --print` for
Cursor's MCP settings. Detail: [claude-code.md](claude-code.md).

## Changing this repository

Checks to run before proposing a change, and the conventions the scripts
follow: [CONTRIBUTING.md](../CONTRIBUTING.md).
