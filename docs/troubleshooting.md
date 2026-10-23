# Troubleshooting

Start with `./bin/status`. It checks containers, WordPress, abilities, the MCP
endpoint and the Claude Code registration, in that order; the first failure
names the layer. A request travels left to right, so test right to left:

```text
Your Agent    →  MCP Adapter        →  Abilities API         →  WordPress     on Docker
claude mcp       ./bin/test            ./bin/wp ability list    ./bin/status
get wordpress    integration           ./bin/wp ability run     ./bin/logs
```

If `./bin/wp ability run core/get-site-info --user=admin` works but MCP does
not, the fault is in the MCP or authentication layer, not in WordPress.

## Symptom index

| Symptom | Layer |
|---------|-------|
| Docker not running, Compose v1, `docker: permission denied` | [Docker](#docker) |
| Port 8080 or 3307 already in use | [Ports](#ports) |
| `db` never healthy, `Error establishing a database connection` | [Database](#database) |
| Filesystem errors, `bin/*: Permission denied` | [File ownership](#file-ownership) |
| Site does not respond, `wp core install` fails, `/wp-json/` 404 | [WordPress](#wordpress) |
| Plugin will not install or activate | [Plugins](#plugins) |
| `wp ability` missing, empty list, ability not over MCP, execution fails | [Abilities API](#abilities-api) |
| MCP 404 or 401, session errors, `GET` 405 | [MCP Adapter](#mcp-adapter) |
| No tools, only three tools, every call fails, port changed | [Claude Code](#claude-code) |
| Claude Code or Cursor asks before every write | [Approval prompts](#approval-prompts) |
| `.env` change ignored, full reset, disk space, rotating credentials | [Reset and credentials](#reset-and-credentials) |

---

## Docker and setup

### Docker

| Symptom | Cause | Fix |
|---------|-------|-----|
| `The Docker daemon is not running` | Docker stopped; check with `docker info` | macOS / Windows: start Docker Desktop. Linux: `sudo systemctl start docker` |
| `docker compose (v2) is unavailable` | Compose v1 (`docker-compose`) or no plugin; `docker compose version` must print v2+ | Install the Compose plugin or update Docker Desktop |
| `docker: permission denied` (Linux) | User not in the `docker` group | `sudo usermod -aG docker "$USER"`, then a new login shell |

### Ports

`127.0.0.1:8080 is already in use by something else`. Find the holder:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN                  # macOS / Linux
netstat -ano -p tcp | grep ':8080 .*LISTENING'    # Windows
```

Stop it, or move this project:

```bash
sed -i.bak 's/^WP_PORT=.*/WP_PORT=8081/' .env    # or edit .env by hand
./bin/start
./bin/connect          # the registered MCP URL still points at the old port
```

No reinstall: `WP_HOME` reads the port at runtime. `DB_PORT` works the same way
(default 3307, since a local MySQL usually holds 3306). Codex: also update the
`url` in `.codex/config.toml` ([codex.md](codex.md)).

### Database

Diagnose with `./bin/logs db` and `docker compose ps`.

| Symptom | Cause | Fix |
|---------|-------|-----|
| `db` never healthy | `MYSQL_USER` or `MYSQL_PASSWORD` changed after the first run; the volume keeps the old ones | `./bin/reset` |
| `db` never healthy | Corrupt volume after an abrupt shutdown | `./bin/reset` |
| `db` never healthy | Not enough memory | Docker Desktop memory limit 4 GB or more |
| `Error establishing a database connection` | WordPress started before MariaDB finished first-run init (rare; `depends_on: service_healthy` normally prevents it) | `./bin/stop && ./bin/start`, then `./bin/wp db check` |

### File ownership

| Symptom | Cause | Fix |
|---------|-------|-----|
| Uploads or plugin installs fail with a filesystem error | Root-owned files in `/var/www/html` (WordPress and `./bin/wp` run as `www-data`) | `docker compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content` |
| `bin/*: Permission denied` after cloning | Git dropped the executable bit (some Windows setups) | `chmod +x bin/* tests/*.sh docker/wordpress/bin/*`, or `bash bin/setup` |

---

## WordPress

### Site does not respond on `http://localhost:8080`

```bash
./bin/status
./bin/logs wordpress
curl -i http://localhost:8080/
```

Container healthy but curl times out: something intercepts loopback traffic,
usually a full-tunnel VPN.

### `./bin/setup` fails during `wp core install`

Check `./bin/logs wordpress`, `./bin/wp db check`, `./bin/wp core version`. A
half-finished install leaves a state `wp core is-installed` rejects:
`./bin/reset`.

### `/wp-json/` returns 404

Pretty permalinks are not rewritten. Provisioning fails loudly on this; to check
by hand:

```bash
docker compose exec wordpress cat /var/www/html/.htaccess
docker compose exec wordpress apache2ctl -M | grep rewrite
./bin/wp option get permalink_structure       # expects /%postname%/
./bin/wp rewrite flush
```

`docker/wordpress/apache-wordpress.conf` sets `AllowOverride All`; after editing
it, `./bin/setup` rebuilds the image. Meanwhile the API answers at
`http://localhost:8080/?rest_route=/`.

### Plugins

**Install fails.** The ZIPs are GitHub release assets downloaded from inside the
container, so the cause is almost always the network: proxy, TLS interceptor, or
a VPN that geo-blocks the host. Test and retry:

```bash
docker compose exec wordpress curl -sI \
  https://github.com/WordPress/mcp-adapter/releases/download/v0.7.1/mcp-adapter.zip
./bin/wp plugin install \
  https://github.com/WordPress/mcp-adapter/releases/download/v0.7.1/mcp-adapter.zip --force
```

A 404 means a wrong `MCP_ADAPTER_VERSION` or `MS_WP_ABILITIES_VERSION` in
`.env`. The MS WP Abilities asset is named `ms-wp-abilities-<version>.zip`.

**Installs but will not activate.** Run `./bin/wp plugin activate mcp-adapter
--debug` and `./bin/logs --debug`.

- Both plugins need WordPress 6.9+ and PHP 7.4+: `./bin/wp core version`,
  `docker compose exec wordpress php -v`.
- MS WP Abilities needs MCP Adapter active first; keep that order by hand.

---

## Abilities API

The full no-MCP command set is in
[development.md](development.md#the-abilities-without-mcp).

| Symptom | Cause | Fix |
|---------|-------|-----|
| `wp ability` is not a registered command | Stale image without `wp-cli/ability-command` (check `/usr/local/etc/wp-cli.yml`, `/usr/local/lib/wp-cli-packages/ability-command`, `./bin/wp --info`) | `docker compose build --no-cache wordpress && ./bin/start` |
| `wp ability list` is empty | WordPress older than 6.9, or MS WP Abilities inactive | See below |
| Registered but not over MCP | Abilities are private unless `meta.public` or `meta.mcp.public` | Check the meta, below, or **Tools → WP Abilities** in wp-admin |
| Execution fails (`isError: true`) | Ability fault or transport fault | Run it without MCP, below |

Empty list:

```bash
./bin/wp plugin list
./bin/wp eval 'var_dump( function_exists( "wp_register_ability" ) );'
```

`false`: WordPress is older than 6.9; check `WORDPRESS_IMAGE` in `.env`. `true`:
MS WP Abilities is inactive.

Not over MCP:

```bash
./bin/wp ability list --field=name | sort > /tmp/registered
./bin/wp ability get miriamschwab/get-posts --fields=name,meta
```

Failed execution, without MCP:

```bash
./bin/wp ability can-run miriamschwab/create-post --user=admin
./bin/wp ability validate miriamschwab/create-post --input='{"title":"x"}'
./bin/wp ability run miriamschwab/get-posts --input='{"per_page":1}' --user=admin
./bin/logs --debug
```

`permission_denied`: the user lacks `edit_posts` (content) or `activate_plugins`
(plugins). `./bin/wp user list --fields=user_login,roles` must show
`WP_ADMIN_USER` as administrator.

---

## MCP Adapter

| Symptom | Cause | Fix |
|---------|-------|-----|
| 404 at `/wp-json/mcp/mcp-adapter-default-server` | MCP Adapter inactive, or rewrite rules not flushed | `./bin/setup`. Check: `./bin/wp plugin is-active mcp-adapter`, `curl -s http://localhost:8080/wp-json/ \| grep -o '"mcp[^"]*"'`, `./bin/wp rewrite flush` |
| 401 with the right credential | See below | See below |
| `Missing Mcp-Session-Id header` | Client skipped the handshake; every request after `initialize` must carry its `Mcp-Session-Id`. Claude Code does; hand-rolled curl often does not | [development.md](development.md#speaking-mcp-by-hand), [architecture.md](architecture.md#mcp-transport), or `mcp_request()` in `tests/lib.sh` |
| `Invalid or expired session` | Sessions expire after a day idle; at most 32 per user | Send `initialize` again |
| `GET` returns 405 | Expected: no SSE streaming yet; POST/DELETE only | None |

### 401 with the right credential

```bash
./bin/wp user application-password list admin
docker compose exec -T wordpress wp-app-password available   # expects exit 0
curl -s -u "admin:$(cat .secrets/application-password)" \
  http://localhost:8080/wp-json/wp/v2/users/me
```

| Finding | Cause | Fix |
|---------|-------|-----|
| `wp-app-password available` fails | WordPress does not see the site as local | `./bin/wp eval 'echo wp_get_environment_type();'` must print `local` ([why](security.md#why-plain-http-works-and-why-that-matters)) |
| `/wp/v2/users/me` 401 with a correct password | Apache drops the `Authorization` header | Check both places that pass it: `docker compose exec wordpress grep -r Authorization /etc/apache2/conf-enabled/` and `docker compose exec wordpress grep Authorization /var/www/html/.htaccess` |
| Password was rotated | Old credential registered | `rm .secrets/application-password && ./bin/setup && ./bin/connect` |

---

## Your agent

### Claude Code

Registration and verification: [claude-code.md](claude-code.md#verify-the-connection).

| Symptom | Cause | Fix |
|---------|-------|-----|
| `claude mcp get wordpress` finds nothing | Registration is `local` scope, keyed to the project path | Run from the repository root; if already there, `./bin/connect` |
| Connected, but no WordPress tools | MCP config is read at session start | Restart the session |
| Tools listed, every call fails | Rotated Application Password: `./bin/reset` issued a new one, `~/.claude.json` holds the old | Confirm with `./bin/status` and `./bin/test integration`, then `./bin/setup && ./bin/connect` and restart Claude Code |
| Only three tools listed | Correct: the 29 abilities (26 `miriamschwab/*`, 3 `core/*`) sit behind the three meta-tools | [architecture.md](architecture.md#why-three-tools-and-not-thirty) |
| Port changed, calls stopped | Registered URL points at the old port | `./bin/connect`, then restart Claude Code |
| `./bin/connect`: `claude is not on PATH` | Claude Code not installed or not on this shell's `PATH` | Install it. Everything except `./bin/connect` and test layer 4 works without it |

Codex and Cursor: [codex.md](codex.md).

### Approval prompts

Claude Code or Cursor asks before every write ability. That is the approval
gate (`bin/ability-gate`): reads pass, writes and unknown abilities ask, naming
the ability and that it runs as your connected user. Codex uses its own approval policy. `./bin/audit` lists recorded
writes. Details: [security.md](security.md#the-approval-gate).

---

## Reset and credentials

### `.env` changes seem to have no effect

| Read at | Values | Apply with |
|---------|--------|------------|
| Install (stored in the volume) | `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE` | `./bin/reset` |
| Provision | `WP_SITE_TITLE`, `WP_ADMIN_PASSWORD`, `WP_THEME`, version pins | `./bin/setup` |
| Runtime | `WP_PORT` | `./bin/start` |

### Full reset

`./bin/reset` removes both volumes and `.secrets/application-password`; `.env`
survives, so the rebuilt site has the same configuration. Flags:
[development.md](development.md#commands). Run `./bin/connect` afterwards: the
Application Password is new.

### Reclaiming disk space

```bash
docker compose down --volumes --remove-orphans
docker image rm wp-agent-harness-wordpress:local
docker builder prune
```

### Changing local credentials

| Credential | How |
|------------|-----|
| Administrator password | `WP_ADMIN_PASSWORD` in `.env`, then `./bin/setup` |
| Database passwords | Edit `.env`, then `./bin/reset`; the volume holds the old ones |
| Application Password | `rm .secrets/application-password && ./bin/setup && ./bin/connect` |

---

## Still stuck

```bash
./bin/status
./bin/logs
./bin/logs --debug
./bin/wp ability list
./bin/test --skip-claude
docker compose config
```

Failures in the MCP Adapter or MS WP Abilities themselves, not this wiring,
belong upstream:

- https://github.com/WordPress/mcp-adapter/issues
- https://github.com/miriamschwab/ms-wp-abilities/issues
