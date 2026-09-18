# wordpress-claude-mcp

A disposable, reproducible local WordPress site that Claude Code can drive as a
real development and site-administration agent, over the official WordPress MCP
Adapter.

**Development only.** See [Security](#security).

## What this is

Three things already exist and work:

- **[WordPress Abilities API](https://developer.wordpress.org/apis/abilities-api/)** (WordPress 6.9+) — core's standard way to register discrete, permission-checked capabilities.
- **[MCP Adapter](https://github.com/WordPress/mcp-adapter)** — the official WordPress package that exposes those abilities over the Model Context Protocol.
- **[MS WordPress Abilities](https://github.com/miriamschwab/ms-wp-abilities)** — Miriam Schwab's plugin, which registers 26 abilities covering posts, pages, taxonomy, media, users, settings, plugins, themes and a generic REST bridge.

What did not exist is a repository you can clone on a new machine and have all
of it running against Claude Code a few minutes later, pinned to exact versions,
with tests that prove the whole chain actually works.

That is this repository. It contains **no MCP server, no abilities framework and
no WordPress plugin of its own**. Every one of those already exists upstream and
is used as a dependency. What is here is the local infrastructure, the
authentication wiring, the developer commands, the tests and the documentation.

## Why it exists

- Reproducibility — every version is pinned in `.env`, so the same clone produces the same site.
- Authentication that is real — a WordPress Application Password, never disabled auth.
- A tested chain — four test layers, up to and including a genuine headless Claude Code session that creates, reads, modifies and trashes a page.
- A disposable environment — `./bin/reset` destroys everything and rebuilds it.

## Architecture

```
  ┌─────────────────────────────────────────────┐
  │ host machine                                │
  │                                             │
  │   Claude Code                               │
  │       │                                     │
  │       │ MCP Streamable HTTP + Basic auth    │
  │       │ (WordPress Application Password)    │
  │       ▼                                     │
  │   127.0.0.1:8080                            │
  └───────┬─────────────────────────────────────┘
          │
  ┌───────▼─────────────────────────────────────┐
  │ docker compose                              │
  │                                             │
  │  wordpress ──────────────────┐              │
  │    Apache + PHP 8.3          │              │
  │    /wp-json/mcp/mcp-adapter-default-server  │
  │        │                     │              │
  │        ▼                     │              │
  │    MCP Adapter               │              │
  │        │                     │              │
  │        ▼                     │              │
  │    WordPress Abilities API   │  WP-CLI      │
  │        │                     │  wp ability  │
  │        ▼                     │  (no MCP)    │
  │    MS WP Abilities  ◄────────┘              │
  │        │                                    │
  │        ▼                                    │
  │    WordPress core + REST                    │
  │      Twenty Twenty-Five, content, plugins,  │
  │      themes, media, site configuration      │
  │        │                                    │
  │  db ◄──┘  MariaDB 11.8 (named volume)       │
  └─────────────────────────────────────────────┘
```

Full detail, including which state is persistent and which is disposable:
[docs/architecture.md](docs/architecture.md).

## Requirements

| Tool | Why | Notes |
|------|-----|-------|
| Docker + Compose v2 | runs WordPress and MariaDB | Docker Desktop on macOS/Windows, Docker Engine on Linux |
| Git | clone | |
| Bash | the `./bin` commands | Git Bash on Windows, the system shell elsewhere |
| curl | health and MCP checks | ships with Git Bash and macOS |
| Claude Code | the point of the exercise | only `./bin/connect` and test layer 4 need it |
| jq | the test suite only | `brew install jq` · `apt install jq` · `winget install jqlang.jq` |

Tested on Windows 11 (Git Bash), and in GitHub Actions on Ubuntu.

## Quick start

```bash
git clone <this-repository>
cd wordpress-claude-mcp

cp .env.example .env     # optional: ./bin/setup does this for you

./bin/setup              # build, start, install WordPress, issue credentials
./bin/connect            # register the MCP server with Claude Code

cd . && claude           # start Claude Code in this directory
```

Then ask Claude Code:

> Inspect the local WordPress site. Tell me the WordPress version, active theme,
> active plugins, site title, available post types and current content structure.

`./bin/setup` is idempotent — run it as often as you like. It never destroys
content; only `./bin/reset` does that.

## Environment variables

All of them live in `.env`, which is git-ignored. `.env.example` is the tracked
template; `./bin/setup` copies it and replaces every `CHANGE_ME` with a freshly
generated random secret.

| Variable | Default | Purpose |
|----------|---------|---------|
| `COMPOSE_PROJECT_NAME` | `wordpress-claude-mcp` | Docker Compose project and volume prefix |
| `WP_PORT` | `8080` | host port for WordPress, bound to `127.0.0.1` |
| `DB_PORT` | `3307` | host port for MariaDB, bound to `127.0.0.1` |
| `WORDPRESS_IMAGE` | `wordpress:7.1.0-php8.3-apache` | pinned base image |
| `MARIADB_IMAGE` | `mariadb:11.8.9` | pinned database image |
| `WP_CLI_VERSION` | `2.12.0` | WP-CLI phar, checksum-verified at build |
| `WP_CLI_ABILITY_COMMAND_VERSION` | `1.0.2` | provides `wp ability` |
| `MCP_ADAPTER_VERSION` | `0.6.1` | MCP Adapter release tag |
| `MS_WP_ABILITIES_VERSION` | `1.12.0` | MS WP Abilities release tag |
| `WP_THEME` | `twentytwentyfive` | installed and activated by setup |
| `WP_SITE_TITLE` | `WordPress Claude MCP` | site title |
| `WP_ADMIN_USER` | `admin` | development administrator login |
| `WP_ADMIN_EMAIL` | `admin@wordpress-claude-mcp.test` | administrator email |
| `WP_ADMIN_PASSWORD` | generated | **wp-admin** password — not the MCP credential |
| `MCP_APP_PASSWORD_NAME` | `claude-code-mcp` | label of the Application Password |
| `MCP_SERVER_NAME` | `wordpress` | name Claude Code registers the server under |
| `MYSQL_DATABASE` | `wordpress` | database name |
| `MYSQL_USER` | `wordpress` | database user |
| `MYSQL_PASSWORD` | generated | database password |
| `MYSQL_ROOT_PASSWORD` | generated | database root password |

## Commands

| Command | What it does |
|---------|--------------|
| `./bin/setup` | Validate prerequisites, create `.env`, build, start, install and configure WordPress, issue the Application Password, verify the stack. Idempotent. |
| `./bin/start` | Start the Docker services and wait for health. |
| `./bin/stop` | Stop the services. Volumes and content survive. |
| `./bin/reset` | **Destructive.** Remove containers, both volumes and the stored credential, then rebuild. Asks for confirmation; `--yes` skips it, `--no-setup` destroys without rebuilding. |
| `./bin/status` | Container health, WordPress health, ability registration, MCP endpoint health, Claude Code registration. |
| `./bin/logs` | Docker logs. `./bin/logs -f wordpress` follows one service; `./bin/logs --debug` shows WordPress's own PHP debug log. |
| `./bin/test` | The full test suite. `--skip-claude` skips the layer that costs model turns; a file name (`repo`, `smoke`, `integration`, `claude-code`) runs one. |
| `./bin/connect` | Register the MCP server with Claude Code. `--remove` unregisters, `--print` shows the endpoint and header without writing anything. |
| `./bin/wp` | WP-CLI inside the container, e.g. `./bin/wp ability list`. |

`make help` lists the same set as Make targets.

### Starting, stopping and resetting

```bash
./bin/start                # resume where you left off
./bin/stop                 # stop, keep everything
./bin/reset                # destroy volumes, rebuild from scratch (prompts)
./bin/reset --yes          # same, unattended
./bin/reset --no-setup     # destroy only
```

After `./bin/reset` the Application Password is new, so run `./bin/connect`
again.

## URLs

| | |
|---|---|
| Site | `http://localhost:8080` |
| Admin | `http://localhost:8080/wp-admin/` |
| REST API | `http://localhost:8080/wp-json/` |
| **MCP endpoint** | `http://localhost:8080/wp-json/mcp/mcp-adapter-default-server` |

All bound to `127.0.0.1`. Change the port with `WP_PORT` in `.env`, then
`./bin/start` — no reinstall is needed.

## Claude Code connection

```bash
./bin/connect
```

registers an HTTP MCP server in Claude Code's **local** scope, which means this
project only and stored in `~/.claude.json`, outside this repository. It is
equivalent to:

```bash
claude mcp add --transport http --scope local \
  wordpress http://localhost:8080/wp-json/mcp/mcp-adapter-default-server \
  --header "Authorization: Basic <base64 of admin:application-password>"
```

Verify with `claude mcp get wordpress`, remove with `./bin/connect --remove`.
Details, alternative scopes and the STDIO alternative:
[docs/claude-code.md](docs/claude-code.md).

## Authentication

Two different credentials, easily confused:

| | Used for | Where it lives |
|---|---|---|
| **Administrator password** | logging into `/wp-admin/` in a browser | `WP_ADMIN_PASSWORD` in `.env` |
| **Application Password** | MCP and REST requests from Claude Code | `.secrets/application-password`, and Claude Code's own config |

The Application Password is generated by WordPress, shown exactly once, and
never written to a tracked file. `./bin/setup` reuses the existing one when it
still authenticates and issues a new one when it does not.

WordPress refuses Application Password authentication over plain HTTP unless it
considers the site local, so `wp-config.php` sets
`WP_ENVIRONMENT_TYPE = 'local'`. That is the only concession to the
`http://localhost` setup; no authentication is disabled anywhere.

## What Claude Code can actually do

The MCP Adapter's default server exposes **three meta-tools**, not one tool per
ability:

- `mcp-adapter-discover-abilities`
- `mcp-adapter-get-ability-info`
- `mcp-adapter-execute-ability`

Claude discovers what exists, fetches the schema it needs, then executes. This
is the adapter's deliberate design — it keeps `tools/list` at three schemas no
matter how many abilities the site registers. Behind it, this site currently
registers 32 abilities: 26 from MS WP Abilities (`miriamschwab/*`), 3 WordPress
core abilities opted into MCP (`core/*`), and the adapter's own 3.

See the whole list with:

```bash
./bin/wp ability list
```

## Example prompts

Worked examples, each with the abilities it exercises and what to expect:
[examples/README.md](examples/README.md).

- [Inspect the site](examples/inspect-site.md)
- [Create content](examples/create-content.md)
- [Modify content](examples/modify-content.md)
- [Theme inspection](examples/theme.md)
- [Media and alt text](examples/media.md)
- [Plugins and updates](examples/plugins.md)
- [Build a feature](examples/site-development.md)

## Testing

```bash
./bin/test                 # everything
./bin/test --skip-claude   # all but layer 4, no model turns
./bin/test repo            # repository integrity only, no Docker needed
./bin/test smoke           # one file only
```

| Layer | File | Verifies |
|-------|------|----------|
| 0 Repository | `tests/repo.sh` | `.gitignore` coverage, nothing secret tracked, no credential patterns in tracked content, every script parses and is executable, documented files really are tracked, versions in `.env.example` and this README agree, loopback-only bindings |
| 1 Infrastructure | `tests/smoke.sh` | Compose config, services, health, loopback-only port bindings, `.env` completeness |
| 2 WordPress / Abilities | `tests/smoke.sh` | WordPress ≥ 6.9, PHP ≥ 7.4, active theme, both plugins at the pinned versions, `wp_register_ability()`, every expected ability registered, `wp ability run` |
| 3 MCP protocol | `tests/integration.sh` | 401 without auth and with a wrong password, `initialize`, `Mcp-Session-Id` issuance and enforcement, protocol negotiation, `notifications/initialized`, `tools/list`, all three meta-tools, discovery, schema retrieval, execution, a create/read/modify/verify/trash cycle, session termination |
| 4 Claude Code | `tests/claude-code.sh` | A real headless `claude -p` session that inspects the site, creates a draft page, reads it back, modifies it and trashes it — each step checked against the database with WP-CLI |

Tests create only uniquely named content and delete it again. They never touch
the rest of the site.

## Updating dependencies

Every version is a variable in `.env`. To move one:

1. Check the upstream release you want.
   ```bash
   gh release list --repo WordPress/mcp-adapter
   gh release list --repo miriamschwab/ms-wp-abilities
   ```
2. Edit the variable in `.env` (and `.env.example`, so the next clone gets it).
3. Re-run setup. `wp-provision` notices the version drift and reinstalls in place.
   ```bash
   ./bin/setup
   ./bin/test --skip-claude
   ```
4. For `WORDPRESS_IMAGE`, `MARIADB_IMAGE`, `WP_CLI_VERSION` or
   `WP_CLI_ABILITY_COMMAND_VERSION`, the image is rebuilt by `./bin/setup`.
   A database major-version change needs `./bin/reset`.

Nothing tracks a moving `trunk` or `main` branch. Plugins come from tagged
GitHub release ZIPs, WP-CLI from a checksum-verified release phar. More:
[docs/development.md](docs/development.md).

## Troubleshooting

`./bin/status` first — it localises the failure to a layer. Then
[docs/troubleshooting.md](docs/troubleshooting.md), which covers Docker not
running, ports in use, the database not coming up, plugin install and activation
failures, missing abilities, MCP authentication failures, Claude Code not
connecting, stale volumes, changing ports and rotating credentials.

The useful mental model is the debugging hierarchy:

```
WordPress works  →  abilities work  →  MCP works  →  Claude Code works
 ./bin/status       ./bin/wp ability   tests/         tests/
                    list               integration.sh claude-code.sh
```

If `./bin/wp ability run core/get-site-info --user=admin` works but MCP does
not, the problem is in the MCP or auth layer, not in WordPress.

## Security

This is a **development-only** toolkit. Whatever connects to the MCP endpoint
can create and publish content, install and activate plugins, update themes and
issue arbitrary REST API writes as the administrator.

- Both ports bind to `127.0.0.1` only.
- Authentication is always on. An unauthenticated request gets HTTP 401 — the test suite asserts it.
- Credentials are never committed. `.env` and `.secrets/` are ignored; the MCP credential lives in Claude Code's own config.
- The preview/confirm model in MS WP Abilities is a working convention between you and the agent, not a security boundary enforced by code.

Do not expose this to the internet, do not point it at production data, and do
not reuse its credentials anywhere else. Full model:
[docs/security.md](docs/security.md).

## Project structure

```
wordpress-claude-mcp/
├── .github/workflows/test.yml   CI: shell syntax, compose validation, secret scan, full stack
├── bin/                         the developer commands
│   ├── lib.sh                   shared helpers, sourced by the rest
│   ├── setup  start  stop  reset
│   ├── status  logs  test  connect  wp
├── docker/wordpress/            the WordPress image
│   ├── Dockerfile               base image + WP-CLI + wp ability
│   ├── apache-wordpress.conf    AllowOverride and the Authorization header
│   ├── wp-cli.yml               WP-CLI global config
│   ├── ability-command-autoload.php
│   └── bin/                     scripts that run inside the container
│       ├── wp                   WP-CLI wrapper, drops root to www-data
│       ├── wp-provision         idempotent WordPress provisioning
│       └── wp-app-password      Application Password lifecycle
├── docs/
│   ├── architecture.md  claude-code.md  development.md
│   ├── security.md      troubleshooting.md
├── examples/                    prompts that work against this site
├── tests/
│   ├── lib.sh                   assertions and a minimal MCP HTTP client
│   ├── repo.sh                  repository integrity, no Docker needed
│   ├── smoke.sh                 layers 1-2
│   ├── integration.sh           layer 3
│   └── claude-code.sh           layer 4
├── .env.example                 tracked template; .env is ignored
├── CLAUDE.md                    context Claude Code reads in this repository
├── docker-compose.yml
└── Makefile
```

Not tracked, by design: `.env`, `.secrets/`, the database, the WordPress
install, uploads, logs, and Claude Code's MCP registration.

## Versions

| Component | Version | Source |
|-----------|---------|--------|
| WordPress | 7.1 | `wordpress:7.1.0-php8.3-apache` |
| PHP | 8.3 | same image |
| Apache | 2.4 | same image |
| MariaDB | 11.8.9 | `mariadb:11.8.9` |
| WP-CLI | 2.12.0 | GitHub release phar, SHA-512 verified |
| `wp-cli/ability-command` | 1.0.2 | GitHub release tarball |
| MCP Adapter | 0.6.1 | GitHub release ZIP |
| MS WordPress Abilities | 1.12.0 | GitHub release ZIP |
| Twenty Twenty-Five | 1.5 | wordpress.org |
| MCP protocol | 2025-11-25 | negotiated; the adapter also supports 2025-06-18 and 2024-11-05 |

Both plugins require WordPress 6.9+ (for the Abilities API) and PHP 7.4+.

## Licence

[MIT](LICENSE) for this repository. Every upstream component keeps its own
licence; none of their code is vendored here.
