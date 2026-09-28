# wp-agent-harness

A disposable, reproducible local WordPress site that Claude Code drives as a
real development and site-administration agent, over the official WordPress MCP
Adapter.

[![test](https://github.com/Foreveryone-berlin/wp-agent-harness/actions/workflows/test.yml/badge.svg)](https://github.com/Foreveryone-berlin/wp-agent-harness/actions/workflows/test.yml)
[![licence: MIT](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)
[![WordPress 7.1](https://img.shields.io/badge/WordPress-7.1-21759b.svg)](https://wordpress.org/)

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
no WordPress plugin of its own** — every one of those exists upstream and is used
as a dependency. What is here is the local infrastructure, the authentication
wiring, the developer commands, the tests and the documentation.

Use it as a starting point for WordPress work: clone or use it as a template,
run one command, and you have an agent-drivable site. `./bin/reset` throws it
away and rebuilds it.

## Quick start

```bash
git clone https://github.com/Foreveryone-berlin/wp-agent-harness.git
cd wp-agent-harness

./bin/setup     # build, start, install WordPress, issue credentials
./bin/connect   # register the MCP server with Claude Code
claude          # start Claude Code in this directory
```

Then ask:

> Inspect the local WordPress site. Tell me the WordPress version, active theme,
> active plugins, site title, available post types and current content structure.

`./bin/setup` is idempotent. It never destroys content; only `./bin/reset` does.

### Reusing it for another project

This repository is a GitHub template, so **Use this template** gives you your
own copy. Change three things in `.env` and a second site runs beside this one
without collision:

```bash
COMPOSE_PROJECT_NAME=my-project   # Docker project and volume prefix
WP_PORT=8081                      # and DB_PORT, if 3307 is taken
WP_SITE_TITLE=My Project
```

Then `./bin/setup && ./bin/connect`. Claude Code registers the server per
project directory, so each clone gets its own registration.

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
  │        │                                    │
  │  db ◄──┘  MariaDB 11.8 (named volume)       │
  └─────────────────────────────────────────────┘
```

Which state is persistent, which is disposable, and why it is built this way:
[docs/architecture.md](docs/architecture.md).

## Commands

| Command | What it does |
|---------|--------------|
| `./bin/setup` | Validate prerequisites, create `.env`, build, start, install and configure WordPress, issue the Application Password, verify the stack. Idempotent. |
| `./bin/start` | Start the Docker services and wait for health. |
| `./bin/stop` | Stop the services. Volumes and content survive. |
| `./bin/reset` | **Destructive.** Remove containers, both volumes and the stored credential, then rebuild. Asks for confirmation; `--yes` skips it, `--no-setup` destroys without rebuilding. Run `./bin/connect` afterwards — the Application Password is new. |
| `./bin/status` | Container health, WordPress health, ability registration, MCP endpoint health, Claude Code registration. |
| `./bin/logs` | Docker logs. `./bin/logs -f wordpress` follows one service; `./bin/logs --debug` shows WordPress's own PHP debug log. |
| `./bin/test` | The test suite. `--skip-claude` skips the layer that costs model turns; a file name (`repo`, `smoke`, `integration`, `claude-code`) runs one. |
| `./bin/connect` | Register the MCP server with Claude Code. `--remove` unregisters, `--print` shows the endpoint and header without writing anything. |
| `./bin/wp` | WP-CLI inside the container, e.g. `./bin/wp ability list`. |

`make help` lists the same set as Make targets.

## URLs

| | |
|---|---|
| Site | `http://localhost:8080` |
| Admin | `http://localhost:8080/wp-admin/` |
| REST API | `http://localhost:8080/wp-json/` |
| **MCP endpoint** | `http://localhost:8080/wp-json/mcp/mcp-adapter-default-server` |

All bound to `127.0.0.1`. Change the port with `WP_PORT` in `.env`, then
`./bin/start` — no reinstall is needed.

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

The rest — image tags, plugin versions, database credentials, the Application
Password label — are documented inline in
[`.env.example`](.env.example). Version pins are listed under
[Versions](#versions); moving one is
[docs/development.md](docs/development.md#updating-dependencies).

## Connecting Claude Code

```bash
./bin/connect
```

registers an HTTP MCP server in Claude Code's **local** scope: this project only,
stored in `~/.claude.json`, outside this repository. Verify with
`claude mcp get wordpress`, remove with `./bin/connect --remove`. Scopes, the
exact `claude mcp add` equivalent, headless use, and the curated WordPress
agent skills under `.claude/skills/` and `.cursor/skills/`:
[docs/claude-code.md](docs/claude-code.md).

Two credentials are easily confused:

| | Used for | Where it lives |
|---|---|---|
| **Administrator password** | logging into `/wp-admin/` in a browser | `WP_ADMIN_PASSWORD` in `.env` |
| **Application Password** | MCP and REST requests from Claude Code | `.secrets/application-password`, and Claude Code's own config |

## What Claude Code can actually do

The MCP Adapter's default server exposes **three meta-tools**, not one tool per
ability:

```
mcp-adapter-discover-abilities   what can this site do?
mcp-adapter-get-ability-info     what does that ability expect?
mcp-adapter-execute-ability      do it
```

Claude discovers what exists, fetches the schema it needs, then executes, so
`tools/list` stays at three schemas however many abilities the site registers.
Behind them this site registers 32 abilities: 26 from MS WP Abilities
(`miriamschwab/*`), 3 WordPress core abilities opted into MCP (`core/*`), and the
adapter's own 3. Why it is built that way:
[docs/architecture.md](docs/architecture.md#why-three-tools-and-not-thirty).

The live list, which is authoritative:

```bash
./bin/wp ability list
```

Worked prompts, each with the abilities it exercises and what to expect:
[examples/](examples/README.md) — [inspect](examples/inspect-site.md),
[create](examples/create-content.md), [modify](examples/modify-content.md),
[theme](examples/theme.md), [media](examples/media.md),
[plugins](examples/plugins.md), [build a feature](examples/site-development.md).

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

## Troubleshooting

`./bin/status` first: it walks the stack in order and the first failing check
names the layer. Then [docs/troubleshooting.md](docs/troubleshooting.md), which
covers Docker, ports, the database, plugin installs, missing abilities, MCP
authentication, Claude Code, stale volumes and credential rotation.

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
[docs/security.md](docs/security.md). To report a vulnerability in this
repository: [SECURITY.md](SECURITY.md).

## Project structure

```
wp-agent-harness/
├── .claude/skills/              curated WordPress agent skills (Claude Code)
├── .cursor/skills/              same pack for Cursor
├── .github/                     CI, issue and PR templates, Dependabot
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
├── docs/                        architecture · claude-code · development
│                                security · troubleshooting
├── examples/                    prompts that work against this site
├── tests/
│   ├── lib.sh                   assertions and a minimal MCP HTTP client
│   ├── repo.sh                  layer 0, no Docker needed
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
Nothing tracks a moving branch.

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) has the development loop, the conventions the
scripts follow, and what CI checks. Changes to this repository run
`./bin/test --skip-claude` before they are proposed.

## Licence

[MIT](LICENSE) for this repository. Every upstream component keeps its own
licence; none of their code is vendored here.
