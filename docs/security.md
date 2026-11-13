# Security model

**This is a development-only toolkit. Do not run it anywhere that matters.**

Every MCP request travels Your Agent → MCP Adapter → Abilities API → WordPress.
Each hop has its own control:

| Hop | Control | Enforced by |
|-----|---------|-------------|
| Your Agent | [Approval gate](#the-approval-gate): reads pass, every write ability asks you | `bin/ability-gate`, Claude Code and Cursor only |
| MCP Adapter | [Application Password](#application-passwords) auth; [loopback-only](#localhost-binding) ports | WordPress core; Compose bindings, `./bin/setup`, `./bin/status` |
| Abilities API | [Capability checks and the `rest-write` hard-block list](#capability-checks-and-the-hard-block-list) | WordPress, MS WP Abilities |
| WordPress | [Audit log](#the-audit-log); disposable state | MS WP Abilities; `./bin/reset` |

Limits, stated once:

- **MCP access is admin access by default.** The agent runs as a WordPress
  administrator unless you [connect with a lower-privileged role](#agent-roles).
- The gate covers MCP writes in Claude Code and Cursor. Codex has no per-call
  hook here.
- Shell access is outside the gate: `./bin/wp`, or `curl` with the Application
  Password, goes through the client's own command approval.

## MCP access here is admin access

The MS WP Abilities set runs as a WordPress **administrator**:

- create, edit, publish and trash any post or page
- create categories and tags; update media metadata
- read the user list and site settings
- **install plugins from wordpress.org and activate them**
- **update plugins and themes**
- **`rest-write`: arbitrary POST/PUT/PATCH/DELETE against any registered REST route**

Installing a plugin is arbitrary code execution in the WordPress container, and
`rest-write` reaches any route any plugin registers. Treat the MCP endpoint like
the admin password.

## Agent roles

`./bin/setup` also creates two lower-privileged logins, each with its own
Application Password. Connect as one with `./bin/connect --role publisher` or
`--role reader` (`--print` takes the same flag); plain `./bin/connect` stays
admin. The abilities' own permission callbacks then refuse whatever the role
lacks, in every client.

| Role | Login (`.env`) | WordPress role | Can | Refused by WordPress |
|------|----------------|----------------|-----|----------------------|
| `admin` | `WP_ADMIN_USER` | administrator | everything above | `rest-write` hard-block list only |
| `publisher` | `WP_PUBLISHER_USER` | `agent_publisher`: editor minus every `delete_*` | create, edit and publish any post or page; terms; media metadata | trash, plugins, themes, menus, site settings, users |
| `reader` | `WP_READER_USER` | `agent_reader`: `read`, `read_private_*`, `edit_posts`, `edit_pages`, `list_users` | read posts, pages, post meta, post types, categories, tags, users; `rest-get` | editing others' content, trash, terms, media, menus, plugins, themes, settings |

The reader is read-only in Claude Code and Cursor, not in WordPress. MS WP
Abilities gates its read abilities on `edit_posts`, the same capability as
`create-post`, and `create-post` does not check `publish_posts`. So WordPress
still lets the reader create, and publish, posts of its own. The
[approval gate](#the-approval-gate) denies every reader write instead of
asking; Codex has no gate, so there the reader can still create posts.

`wp-provision` re-syncs both roles' capabilities on every `./bin/setup`.
`tests/integration.sh` checks what each role may run, over WP-CLI and MCP.

## The approval gate

MS WP Abilities stages content updates in two steps
(`preview-post-update` → `apply-post-update`) and asks the agent to state a REST
write before calling `rest-write`. Both are instructions in the ability
descriptions; the plugin does not check that a human saw anything. A model that
skips confirmation, or follows instructions injected through a post body, a
plugin readme or a REST response, still gets the write through.

`bin/ability-gate` moves the check into the client, where the model cannot skip
it. It runs before every `mcp-adapter-execute-ability` call:

| Client | Wiring | Write call |
|--------|--------|------------|
| Claude Code | `PreToolUse` hook in `.claude/settings.json` | asks you, naming the action and the WordPress user it runs as |
| Cursor | `beforeMCPExecution` hook in `.cursor/hooks.json`, fail-closed | asks you, naming the action and the WordPress user it runs as |
| Codex | none | Codex's own approval policy applies |

- Only explicitly listed reads pass, including `rest-get` and `preview-post-update`.
  The list mirrors the pinned plugin's policy table; `tests/integration.sh`
  fails if the two disagree.
- Everything else asks: all write abilities, any ability from another plugin,
  and any call the gate cannot parse. The prompt names the login the
  agent connects as, from the role `./bin/connect --role` recorded:
  `.secrets/mcp-role` for Claude Code, `.secrets/mcp-role-print` for Cursor
  (`--print`); admin when none is recorded.
- Connected as `reader`, the gate denies those calls instead of asking.
- Project hooks run only in a trusted workspace. Check that the client loaded
  them (Claude Code: `/hooks`).

## Application Passwords

MCP requests authenticate with a WordPress **Application Password**, not the
admin login password. It is:

- generated by WordPress, shown once, revocable on its own
- one per [agent role](#agent-roles), each scoped to its own user and labelled
  `claude-code-mcp` (**Users → Profile → Application Passwords**)
- stored in `.secrets/application-password` (admin) and
  `.secrets/application-password-{publisher,reader}` (git-ignored), and in
  Claude Code's `~/.claude.json`, outside this repository
- kept by `./bin/setup` at mode `0600` (`.env`, each password file) inside a
  `0700` `.secrets/`, where the filesystem enforces Unix modes

Revoke them:

```bash
docker compose exec -T wordpress wp-app-password delete            # admin
docker compose exec -T wordpress wp-app-password delete agent-publisher
docker compose exec -T wordpress wp-app-password delete agent-reader
rm -rf .secrets
./bin/connect --remove
unset WORDPRESS_MCP_BASIC_AUTH   # if you exported it from --print
```

Where the header is exposed:

- `./bin/connect --print` writes the live Basic auth header to stdout (Codex and
  Cursor need it). Keep it out of tickets and logs; clear it from shell history
  on shared machines.
- `claude mcp add --header` puts the header on the process argv briefly. Do not
  run `./bin/connect` on a multi-user host you do not trust.

### Why plain HTTP works, and why that matters

WordPress refuses Application Passwords over plain HTTP unless the site is a
local environment, so `wp-config.php` sets `WP_ENVIRONMENT_TYPE = 'local'`.
**That is the only reason this works over `http://`, and the reason the site
must never be reachable from anywhere else.** No authentication is disabled: an
unauthenticated MCP request gets HTTP 401, and `tests/integration.sh` asserts
that, and the rejection of a wrong password, on every run.

## Localhost binding

Both published ports bind to loopback, not `0.0.0.0`:

```yaml
ports:
  - "127.0.0.1:${WP_PORT:-8080}:80"      # wordpress
  - "127.0.0.1:${DB_PORT:-3307}:3306"    # db
```

Nothing on your network or the internet reaches either service.
`tests/smoke.sh` asserts the binding, so a change that widens it fails CI.
`./bin/setup` and `./bin/status` refuse any Compose publish whose `host_ip` is
not `127.0.0.1`, and refuse `network_mode: host`, overrides included.

Never:

- change the bindings to `0.0.0.0` or drop the host part
- publish the same ports from a `docker-compose.override.yml`
- set `network_mode: host` (Compose then ignores `ports` and binds all
  interfaces)
- tunnel the port (ngrok, Cloudflare Tunnel, `ssh -R`)
- run this on a shared or public host, or behind a reverse proxy

A separate live site is covered in [remote-site.md](remote-site.md); it is
outside the harness and none of these guarantees apply.

## Capability checks and the hard-block list

Every ability runs its own WordPress permission callback against the connected
user. On top of that, MS WP Abilities hard-blocks four things in
`mswpa_rest_write_blocked_reason()`, whatever the agent asks:

- writes to `/wp/v2/users`
- `DELETE` on `/wp/v2/plugins`
- writes to `/wp/v2/settings`
- any `force=true` permanent delete

That is a short list of especially destructive routes, not a general safety
net. Read it in the plugin source before relying on it.

## The audit log

MS WP Abilities records every write-ability call in the `mswpa_write_log`
option at the start of execution, so calls refused by a permission check or the
hard-block list are recorded too. Each entry holds the ability, the user, the
time and identifiers such as `post_id` or `slug`; content is never stored. The
log keeps the last 100 entries. `./bin/audit` prints it.

The database and WordPress install live in Docker volumes; `./bin/reset`
destroys and rebuilds them.

## Credentials stay out of Git

`.gitignore` excludes `.env`, `.secrets/`, `.mcp.json`,
`.claude/settings.local.json`, `*.sql`, `*.pem`, `*.key` and the generated
WordPress state. The tracked `.env.example` holds `CHANGE_ME` placeholders;
`./bin/setup` replaces each with a random 32-character secret, in `.env` only.

The repository is public, and even a private one is cloned, forked, backed up
and read by CI. A committed credential has to be rotated, whatever the
visibility. CI fails if a tracked file matches a credential pattern, or if
`.env`, `.secrets/` or a `.sql` dump shows up in `git ls-files`.

## Download integrity

| Download | Checked | Where |
|----------|---------|-------|
| MCP Adapter and MS WP Abilities release ZIPs | SHA-256 | `wp-provision`, before install |
| `wp-cli/ability-command` tarball | SHA-256 | Docker image build |
| WP-CLI phar | SHA-512 | Docker image build |

Digests sit next to the version pins in `.env.example`.

## What this setup never does

- disable WordPress authentication, nonces or capability checks
- add an unauthenticated endpoint
- widen the MCP Adapter's default permission callbacks
- mark extra abilities public (the public set is whatever MS WP Abilities and
  the adapter ship)
- install a plugin whose job is to bypass something

If a future change needs any of these to make an integration work, the
integration is wrong.

## Making it stricter

Raise the bar on the meta-tools with the adapter's capability filter, in a
must-use plugin:

```php
add_filter( 'mcp_adapter_execute_ability_capability', fn() => 'edit_posts' );
```

Or connect as a lower-privileged user: `./bin/connect --role publisher` or
`--role reader` ([Agent roles](#agent-roles)).

## Reporting

Issues in the MCP Adapter or MS WP Abilities belong upstream:

- https://github.com/WordPress/mcp-adapter/security
- MS WP Abilities: tracker linked in [NOTICE](../NOTICE)
