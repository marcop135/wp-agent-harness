# Architecture

## The whole picture

```
 HOST MACHINE                                    DOCKER
 ─────────────────────────────────────────       ─────────────────────────────────────────

  Claude Code
      │
      │  ./bin/connect registered an HTTP
      │  MCP server in ~/.claude.json
      │
      │  POST /wp-json/mcp/mcp-adapter-default-server
      │  Authorization: Basic <admin:application-password>
      │  Mcp-Session-Id: <uuid>
      ▼
  127.0.0.1:8080 ──────────────────────────────▶ wordpress container
                                                   Apache 2.4 + mod_php 8.3
  ./bin/*  (bash)                                        │
      │  docker compose exec                             ▼
      └───────────────────────────────────────▶   WordPress 7.1 REST API
                                                         │
  ./bin/wp ability list ──────────────────────▶   MCP Adapter 0.7.0
      (WP-CLI, bypasses MCP entirely)                    │  HttpTransport
                                                         │  session store (user meta)
                                                         │  three meta-tools
                                                         ▼
                                                   WordPress Abilities API
                                                   (core, since 6.9)
                                                         │
                                        ┌────────────────┴────────────────┐
                                        ▼                                 ▼
                                  MS WP Abilities 1.12.0            core/* abilities
                                  26 abilities                      get-site-info
                                  miriamschwab/*                    get-user-info
                                        │                           get-environment-info
                                        ▼
                                   WordPress core + REST API
                                        │
              ┌──────────┬──────────┬───┴──────┬──────────┬───────────────┐
              ▼          ▼          ▼          ▼          ▼               ▼
        Twenty        content    plugins    themes      media       site configuration
        Twenty-Five   (posts,
                       pages)
                                        │
                                        ▼
                                   db container
                                   MariaDB 11.8.9
                                   volume: <project>_db_data
```

## Components

### Docker

Two services in `docker-compose.yml`, both published on `127.0.0.1` only, so no
other machine can reach them:

| Service | Image | Data | Health check |
|---------|-------|------|--------------|
| `db` | `mariadb:11.8.9` (11.8 LTS) | volume `<project>_db_data` | `healthcheck.sh --connect --innodb_initialized`; WordPress waits for it |
| `wordpress` | `docker/wordpress/Dockerfile` on `wordpress:7.1.2-php8.3-apache` | volume `<project>_wp_data` (whole install) | curl `/wp-json/` |

### The WordPress image

The Dockerfile adds four things to the official image and changes nothing else:

1. `less`, `unzip`, `curl` and `mariadb-client`, which WP-CLI needs.
2. **WP-CLI 2.12.0** from its GitHub release, verified against the published
   SHA-512.
3. **`wp-cli/ability-command` 1.0.2**, which provides `wp ability`. It is loaded
   through WP-CLI's `require` config key, not `wp package install`. Reason: the
   package declares `wp-cli/wp-cli ^3.0` (it ships with the unreleased WP-CLI
   3.0), but its code only uses `WP_CLI`, `WP_CLI\Formatter` and
   `WP_CLI\Utils`, all present in 2.12. The tarball has no Composer autoloader;
   `docker/wordpress/ability-command-autoload.php` is a PSR-4 shim that stands
   in for it.
4. An Apache conf that sets `AllowOverride All` for `/var/www/html` and copies
   the `Authorization` header into the PHP environment, so `.htaccess` rewrites
   and Application Password auth both work.

`/usr/local/bin/wp` drops from root to `www-data` via `runuser`. WP-CLI
therefore never leaves root-owned files in `wp-content` that Apache cannot
write.

### WordPress

WordPress 7.1.2 on PHP 8.3, installed and configured by
`docker/wordpress/bin/wp-provision` inside the container. It is idempotent: it
checks every item before changing it, so re-running `./bin/setup` creates no
duplicate users, plugins or settings and destroys no content.

The official entrypoint generates `wp-config.php` once, with
`WORDPRESS_CONFIG_EXTRA` adding:

```php
define( 'WP_ENVIRONMENT_TYPE', 'local' );   // makes Application Passwords available over HTTP
define( 'WP_HOME', getenv( 'WORDPRESS_SITE_URL' ) ?: 'http://localhost:8080' );
define( 'WP_SITEURL', WP_HOME );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
define( 'FS_METHOD', 'direct' );            // plugin/theme installs without FTP credentials
define( 'AUTOMATIC_UPDATER_DISABLED', true );
```

- `WP_HOME` reads the environment at runtime: after changing `WP_PORT` in
  `.env`, recreating the container is enough. No reinstall.
- Permalinks are `/%postname%/`, because `/wp-json/`, and with it the MCP
  endpoint, depends on the rewrite rules.

### Twenty Twenty-Five

The default block theme, installed from wordpress.org and activated by
provisioning. No custom theme: the point of this repository is the integration,
and a stock block theme is the most useful thing for an agent to inspect and
extend.

### MCP Adapter

Installed from the pinned GitHub release ZIP, which bundles its Composer
dependencies (`automattic/jetpack-autoloader`, `wordpress/php-mcp-schema`). A
Git checkout would need `composer install` first.

On load it creates its **default server**:

| | |
|---|---|
| Server ID | `mcp-adapter-default-server` |
| Route | `/wp-json/mcp/mcp-adapter-default-server` |
| Transport | HTTP (MCP Streamable HTTP) |
| Auth | logged-in WordPress user with `read` |

### WordPress Abilities API

In core since WordPress 6.9. `wp_register_ability()` registers an ability with
an input schema, an output schema, a permission callback and an execute
callback. **Abilities are private by default**: MCP only sees one whose
`meta.public` or `meta.mcp.public` is `true`.

### MS WP Abilities

Registers **26** abilities in the `miriamschwab/` namespace and opts **3**
core abilities into MCP visibility: **29** in total. Current set:

```
posts/pages   get-posts get-pages get-post-meta get-post-types create-post
              preview-post-update apply-post-update patch-post-content trash-post
taxonomy      get-categories get-tags create-term
media         get-media update-media-meta
users         get-users
site          get-site-settings get-menus
plugins       get-plugins install-plugin activate-plugin update-plugin
themes        get-themes update-theme
updates       get-available-updates
REST bridge   rest-get rest-write
core          core/get-site-info core/get-user-info core/get-environment-info
```

`./bin/wp ability list` prints the live list. Trust it over this table.

### Claude Code

Runs on the host, never in Docker. `./bin/connect` registers the endpoint as an
HTTP MCP server in Claude Code's **local** scope: per project, stored in
`~/.claude.json`, outside this repository, so the credential never gets near
Git. See [claude-code.md](claude-code.md).

## MCP transport

HTTP is the primary transport: Claude Code speaks it natively and the adapter's
default server provides it. Nothing sits between them, no proxy and no custom
server.

The handshake, exercised in full by `tests/integration.sh`:

1. `POST` `initialize` with no session header. The response carries the
   negotiated `protocolVersion`, the server capabilities and an
   `Mcp-Session-Id` header.
2. `POST` `notifications/initialized` with that session header: HTTP 202.
3. Every later `POST` carries `Mcp-Session-Id` and `MCP-Protocol-Version`.
   Without the session header the server returns a JSON-RPC error.
4. `DELETE` with the session header ends the session.

Sessions live in user meta, capped at 32 per user, and expire after a day of
inactivity. `GET` returns 405: the adapter does not implement SSE streaming
yet, which a request/response client does not need.

### Why three tools and not thirty

`tools/list` returns exactly three:

```
mcp-adapter-discover-abilities   list the abilities this site exposes
mcp-adapter-get-ability-info     fetch one ability's full schema
mcp-adapter-execute-ability      run an ability with parameters
```

This is the adapter's layered design, not a limitation:

- Sending every ability's full schema on each connection would spend context
  before any work starts and make the model's choice harder.
- The ability set can grow without reconfiguring anything.
- The cost is one extra round trip when the agent needs a schema it has not
  seen.

The abilities are registered with `/` separators
(`mcp-adapter/discover-abilities`). The adapter's `McpNameSanitizer` turns them
into `-` for MCP tool names, hence `mcp-adapter-discover-abilities`.

### STDIO

The adapter also ships `wp mcp-adapter serve`, a STDIO transport for WP-CLI. It
skips HTTP and authentication entirely, which makes it the way to tell an
adapter fault from a transport fault (command in
[development.md](development.md#speaking-mcp-by-hand)). It is not wired into
Claude Code: that would take a stdio command shelling into Docker, a moving
part that adds no capability.

## Authentication flow

```
Claude Code
  │  Authorization: Basic base64(admin:<application password>)
  ▼
Apache
  │  .htaccess copies Authorization into HTTP_AUTHORIZATION
  ▼
WordPress REST API
  │  wp_authenticate_application_password()
  │  allowed over plain HTTP because WP_ENVIRONMENT_TYPE is 'local'
  ▼
MCP Adapter HttpTransport
  │  transport permission: is_user_logged_in()
  ▼
meta-tool ability
  │  permission: current_user_can( 'read' )
  ▼
target ability
     permission: its own callback, e.g. current_user_can( 'edit_posts' )
```

Four checks, three of them upstream's. Nothing is relaxed to make the
integration work. The one local concession is `WP_ENVIRONMENT_TYPE = 'local'`,
which is what that constant exists for.

## State

### Persistent, outside Git

| State | Where | Destroyed by |
|-------|-------|--------------|
| Database | volume `<project>_db_data` | `./bin/reset` |
| WordPress core, plugins, themes, uploads | volume `<project>_wp_data` | `./bin/reset` |
| `.env` | repository root, ignored | you, by hand |
| Application Password | `.secrets/application-password`, ignored | `./bin/reset` |
| Claude Code MCP registration | `~/.claude.json` | `./bin/connect --remove` |

### Disposable

Both volumes. Everything in them is reproducible from the repository plus
`.env`: `./bin/reset --yes` destroys them and rebuilds the same site. Nothing
that matters should live only there.

### Tracked in Git

Infrastructure and documentation only: `docker-compose.yml`, `docker/`, `bin/`,
`tests/`, `docs/`, `examples/`, `.env.example`, `CLAUDE.md`, `Makefile`,
`README.md`, `LICENSE`, `NOTICE`, `CHANGELOG.md`, `.github/`, plus the curated
WordPress agent skills under `.claude/skills/` and `.cursor/skills/`
(GPL-2.0-or-later upstream copies; see [claude-code.md](claude-code.md)).

### Excluded from Git

| Excluded | Why |
|----------|-----|
| `.env` | admin and database passwords |
| `.secrets/` | the Application Password |
| `.mcp.json`, `.claude/settings.local.json` | can hold credentials |
| database dumps, `*.sql` | development state, not source |
| WordPress core, `wp-content/`, uploads | generated; Docker recreates them |
| logs, `vendor/`, `node_modules/`, `tmp/` | build artefacts |

`.gitignore` covers all of it, and CI re-checks that nothing matching a
credential pattern is tracked.

## Design decisions

| Decision | Why |
|----------|-----|
| **No custom MCP server** | The MCP Adapter is the official WordPress bridge from abilities to MCP. A second server would duplicate it and drift from it. |
| **No custom abilities** | MS WP Abilities is the capability layer. A parallel set would fragment what the agent sees and duplicate work maintained upstream. |
| **No proxy** | Claude Code speaks HTTP MCP and the adapter serves it. A proxy would only be justified if the direct path failed; test layers 3 and 4 show it works. |
| **Release ZIPs, not Git checkouts** | MCP Adapter needs Composer dependencies that a tag tarball lacks and the release ZIP carries. Pinning to a tag also means a clone today and a clone next month build the same site. |
| **One volume for the whole install, not a bind mount** | Bind-mounting `wp-content` brings file-ownership and line-ending problems on Windows and macOS, and puts generated files inside the repository. `./bin/wp` and `docker compose cp` reach the volume; [development.md](development.md) shows how to bind-mount a directory for plugin or theme source anyway. |
| **Local scope for the Claude Code registration** | Project scope means a tracked `.mcp.json` with a credential in it, or an env-var indirection set up separately. Local scope is also per project and keeps the credential out of the repository. |

## Project structure

```
wp-agent-harness/
├── .claude/skills/              curated WordPress agent skills (Claude Code)
├── .codex/config.toml           Codex project MCP (env auth; see docs/codex.md)
├── .cursor/
│   ├── AGENTS.md                Cursor precedence shim
│   └── skills/                  same pack for Cursor
├── .github/                     CI, issue and PR templates, Dependabot
│   └── brand/                   README, OG and social images (SVG source + PNG)
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
│   ├── AGENTS.md                canonical agent index
│   ├── agents/                  contract · runtime policy
│   ├── architecture · claude-code · codex · development
│   └── ai-skills · remote-site · security · troubleshooting
├── examples/                    prompts that work against this site
├── tests/
│   ├── lib.sh                   assertions and a minimal MCP HTTP client
│   ├── repo.sh                  layer 0, no Docker needed
│   ├── smoke.sh                 layers 1-2
│   ├── integration.sh           layer 3
│   └── claude-code.sh           layer 4
├── .env.example                 tracked template; .env is ignored
├── AGENTS.md                    root mirror for tools that only read root
├── CLAUDE.md                    Claude Code entry (points at docs/AGENTS.md)
├── llms.txt                     LLM entry: hard rules and file map
├── docker-compose.yml
└── Makefile
```

Not tracked, by design: `.env`, `.secrets/`, the database, the WordPress
install, uploads, logs, and Claude Code's MCP registration.
