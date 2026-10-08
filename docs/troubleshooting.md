# Troubleshooting

Start with `./bin/status`. It checks the stack in order: containers, WordPress,
abilities, MCP endpoint, Claude Code registration. The first failing check tells
you which section below to read.

```text
WordPress works  →  abilities work  →  MCP works  →  Claude Code works
 ./bin/status       ./bin/wp ability   tests/         tests/
                    list               integration.sh claude-code.sh
```

If `./bin/wp ability run core/get-site-info --user=admin` works but MCP does
not, the fault is in the MCP or authentication layer, not in WordPress.

## Quick index

| Symptom | Section |
|---------|---------|
| Docker not running, Compose v1, permission denied | [Docker](#docker) |
| Port 8080 or 3307 already taken | [Ports](#ports) |
| `db` never healthy, `Error establishing a database connection` | [Database](#database) |
| Site does not load, setup fails at install, `/wp-json/` 404 | [WordPress](#wordpress) |
| Plugin will not install or activate | [Plugins](#plugins) |
| `wp ability` missing, empty list, ability not over MCP | [Abilities](#abilities) |
| MCP 404, 401, session errors, `GET` 405 | [MCP endpoint](#mcp-endpoint) |
| Claude Code sees no tools, or calls fail | [Claude Code](#claude-code) |
| Filesystem errors, `Permission denied` on `bin/*` | [Permissions and file ownership](#permissions-and-file-ownership) |
| `.env` changes ignored, full reset, disk space | [Stale volumes and resetting](#stale-volumes-and-resetting) |
| Rotate admin, database or Application Password | [Changing local credentials](#changing-local-credentials) |

---

## Docker

### `The Docker daemon is not running`

Check with `docker info`.

- macOS / Windows: start Docker Desktop and wait until it reports running.
- Linux: `sudo systemctl start docker`.

### `docker compose (v2) is unavailable`

`docker compose version` must print v2.x or later. Compose v1
(`docker-compose`, with a hyphen) is not supported. Install the Compose plugin,
or update Docker Desktop.

### `docker: permission denied` on Linux

Your user is not in the `docker` group. Add it, then start a new login shell:

```bash
sudo usermod -aG docker "$USER"
```

---

## Ports

### `127.0.0.1:8080 is already in use by something else`

Find what holds the port:

```bash
# macOS / Linux
lsof -nP -iTCP:8080 -sTCP:LISTEN
# Windows
netstat -ano -p tcp | grep ':8080 .*LISTENING'
```

Stop it, or move this project to another port:

```bash
sed -i.bak 's/^WP_PORT=.*/WP_PORT=8081/' .env    # or edit .env by hand
./bin/start
./bin/connect          # the registered MCP URL still points at the old port
```

No reinstall needed: `WP_HOME` reads the port from the container environment at
runtime.

`DB_PORT` works the same way. Its default is 3307 because a local MySQL usually
holds 3306.

---

## Database

### The `db` container never becomes healthy

```bash
./bin/logs db
docker compose ps
```

| Cause | Fix |
|-------|-----|
| `MYSQL_PASSWORD` or `MYSQL_USER` changed after the first run. The image applies them only to an empty data directory, so the volume keeps the old ones. | `./bin/reset` |
| Corrupt volume after an abrupt shutdown | `./bin/reset` |
| Not enough memory | Raise Docker Desktop's memory limit to 4 GB or more |

### `Error establishing a database connection`

On a cold volume WordPress can start before MariaDB finishes its first-run
initialisation. `depends_on: service_healthy` normally prevents this. If you see
it anyway:

```bash
./bin/stop && ./bin/start
./bin/wp db check
```

---

## WordPress

### The site does not respond on `http://localhost:8080`

```bash
./bin/status
./bin/logs wordpress
curl -i http://localhost:8080/
```

Container healthy but curl times out: something on the host intercepts loopback
traffic. Usually a VPN in full-tunnel mode.

### `./bin/setup` fails during `wp core install`

```bash
./bin/logs wordpress
./bin/wp db check
./bin/wp core version
```

A half-finished install leaves the database in a state `wp core is-installed`
rejects. Run `./bin/reset`; nothing here is precious.

### `/wp-json/` returns 404

Pretty permalinks are not being rewritten. Provisioning fails loudly on this; to
check by hand:

```bash
docker compose exec wordpress cat /var/www/html/.htaccess
docker compose exec wordpress apache2ctl -M | grep rewrite
./bin/wp option get permalink_structure       # expects /%postname%/
./bin/wp rewrite flush
```

`docker/wordpress/apache-wordpress.conf` sets `AllowOverride All`. If you edited
it, `./bin/setup` rebuilds the image.

While diagnosing, the API is still reachable at
`http://localhost:8080/?rest_route=/`.

---

## Plugins

### A plugin fails to install

The ZIPs are GitHub release assets, downloaded from inside the container. A
failure is almost always the network: a proxy, a corporate TLS interceptor, or a
VPN that geo-blocks the host. Test the URL from inside the container:

```bash
./bin/logs wordpress
docker compose exec wordpress curl -sI \
  https://github.com/WordPress/mcp-adapter/releases/download/v0.7.0/mcp-adapter.zip
```

Retry by hand:

```bash
./bin/wp plugin install \
  https://github.com/WordPress/mcp-adapter/releases/download/v0.7.0/mcp-adapter.zip --force
```

A 404 means a wrong `MCP_ADAPTER_VERSION` or `MS_WP_ABILITIES_VERSION` in `.env`.
The ms-wp-abilities asset name includes the version:
`ms-wp-abilities-<version>.zip`.

### A plugin installs but will not activate

```bash
./bin/wp plugin activate mcp-adapter --debug
./bin/logs --debug
```

Both plugins need WordPress 6.9+ and PHP 7.4+. Check:

```bash
./bin/wp core version
docker compose exec wordpress php -v
```

MS WP Abilities also needs MCP Adapter active first. Provisioning installs them
in that order; keep it when doing it by hand.

---

## Abilities

### `wp ability` is not a registered command

The command comes from `wp-cli/ability-command`, baked into the image:

```bash
docker compose exec wordpress cat /usr/local/etc/wp-cli.yml
docker compose exec wordpress ls /usr/local/lib/wp-cli-packages/ability-command
./bin/wp --info
```

A missing or empty directory means a stale image. Rebuild:

```bash
docker compose build --no-cache wordpress && ./bin/start
```

### `wp ability list` returns nothing

```bash
./bin/wp plugin list
./bin/wp eval 'var_dump( function_exists( "wp_register_ability" ) );'
```

- `false`: WordPress is older than 6.9. Check `WORDPRESS_IMAGE` in `.env`.
- `true` with an empty list: ms-wp-abilities is inactive.

### An ability is registered but does not appear over MCP

Abilities are private by default. Only `meta.public` or `meta.mcp.public`
exposes them over MCP. Check an ability's meta:

```bash
./bin/wp ability list --field=name | sort > /tmp/registered
./bin/wp ability get miriamschwab/get-posts --fields=name,meta
```

Faster: **Tools → WP Abilities** in wp-admin shows the MCP-public flag for every
ability on the site.

### An ability execution fails

The MCP response carries `isError: true` and the WordPress error message. Run
the same ability without MCP to tell an ability fault from a transport fault:

```bash
./bin/wp ability can-run miriamschwab/create-post --user=admin
./bin/wp ability validate miriamschwab/create-post --input='{"title":"x"}'
./bin/wp ability run miriamschwab/get-posts --input='{"per_page":1}' --user=admin
./bin/logs --debug
```

`permission_denied` means the user lacks the required capability: `edit_posts`
for content, `activate_plugins` for plugin work. Check `WP_ADMIN_USER` is an
administrator:

```bash
./bin/wp user list --fields=user_login,roles
```

---

## MCP endpoint

### 404 at `/wp-json/mcp/mcp-adapter-default-server`

Cause: MCP Adapter inactive, or rewrite rules not flushed. `./bin/setup` fixes
both. To check:

```bash
./bin/wp plugin is-active mcp-adapter && echo active
curl -s http://localhost:8080/wp-json/ | grep -o '"mcp[^"]*"' | head
./bin/wp rewrite flush
```

### 401 with the right credential

```bash
./bin/wp user application-password list admin
docker compose exec -T wordpress wp-app-password available   # expects exit 0
curl -s -u "admin:$(cat .secrets/application-password)" \
  http://localhost:8080/wp-json/wp/v2/users/me
```

- **`wp-app-password available` fails:** WordPress does not consider the site
  local. Check `WP_ENVIRONMENT_TYPE`:
  ```bash
  ./bin/wp eval 'echo wp_get_environment_type();'     # expects: local
  ```
- **`/wp/v2/users/me` returns 401 with a correct password:** Apache is not
  passing the `Authorization` header to PHP. The image handles this in two
  places, `docker/wordpress/apache-wordpress.conf` and the `.htaccess` rewrite.
  Check both are intact:
  ```bash
  docker compose exec wordpress grep -r Authorization /etc/apache2/conf-enabled/
  docker compose exec wordpress grep Authorization /var/www/html/.htaccess
  ```
- **Password was rotated:** re-issue and re-register:
  ```bash
  rm .secrets/application-password && ./bin/setup && ./bin/connect
  ```

### `Missing Mcp-Session-Id header`

The client skips the handshake. Every request after `initialize` must carry the
`Mcp-Session-Id` from the initialize response. Claude Code does this; hand-rolled
curl does not. See [architecture.md](architecture.md#mcp-transport), or
`mcp_request()` in `tests/lib.sh` for a 20-line reference implementation.

### `Invalid or expired session`

Sessions expire after a day of inactivity, and each user keeps at most 32. Send
`initialize` again to start a new one.

### `GET` returns 405

Expected. The adapter has no SSE streaming yet; the endpoint is POST/DELETE
only.

---

## Claude Code

### `claude mcp get wordpress` finds nothing

The registration is `local` scope, keyed to the project path. Run the command
from the repository directory. If you already are, run `./bin/connect`.

### Connected, but no WordPress tools in the session

Claude Code reads MCP configuration at start. Restart the session.

### Tools are there but every call fails

Almost always a rotated Application Password: `./bin/reset` issues a new one,
and `~/.claude.json` still holds the old one. First confirm the endpoint works:

```bash
./bin/status
./bin/test integration
```

Then re-register and restart Claude Code:

```bash
./bin/setup && ./bin/connect
```

### Only three tools are listed

Correct. `mcp-adapter-discover-abilities`, `mcp-adapter-get-ability-info` and
`mcp-adapter-execute-ability` are the whole public surface. The 29 abilities
(26 `miriamschwab/*` + 3 `core/*`) sit behind them. See
[architecture.md](architecture.md#ms-wp-abilities) and
[architecture.md](architecture.md#why-three-tools-and-not-thirty).

### The port changed and calls stopped working

The registered URL still points at the old port. Run `./bin/connect`, then
restart Claude Code.

### `./bin/connect` fails with `claude is not on PATH`

Claude Code is not installed, or not on this shell's `PATH`. `./bin/setup` only
warns about it: everything except `./bin/connect` and test layer 4 works without
it.

---

## Permissions and file ownership

### Uploads or plugin installs fail with a filesystem error

WordPress owns `/var/www/html` as `www-data`. `./bin/wp` runs as that user so
WP-CLI leaves no root-owned files. If something else did:

```bash
docker compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content
```

### `bin/*: Permission denied` after cloning

Git did not keep the executable bit (some Windows configurations):

```bash
chmod +x bin/* tests/*.sh docker/wordpress/bin/*
```

Or run through bash: `bash bin/setup`.

---

## Stale volumes and resetting

### Changes to `.env` seem to have no effect

When each value is read decides how to apply a change:

| Read at | Values | Apply with |
|---------|--------|------------|
| Install (first run, stored in the volume) | `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE` | `./bin/reset` |
| Provision | `WP_SITE_TITLE`, `WP_ADMIN_PASSWORD`, `WP_THEME`, version pins | `./bin/setup` |
| Runtime | `WP_PORT` | `./bin/start` |

### Full reset

```bash
./bin/reset            # prompts, then rebuilds
./bin/reset --yes      # unattended
./bin/reset --no-setup # destroy only
./bin/connect          # afterwards: the Application Password is new
```

This removes both volumes and `.secrets/application-password`. `.env` survives,
so the rebuilt site has the same configuration.

### Reclaiming disk space

```bash
docker compose down --volumes --remove-orphans
docker image rm wp-agent-harness-wordpress:local
docker builder prune
```

---

## Changing local credentials

| Credential | How |
|------------|-----|
| Administrator password | Edit `WP_ADMIN_PASSWORD` in `.env`, then `./bin/setup`. Provisioning syncs it. |
| Database passwords | Edit `.env`, then `./bin/reset`. They cannot change in place; the volume holds the old ones. |
| Application Password | `rm .secrets/application-password && ./bin/setup && ./bin/connect` |

---

## Still stuck

These six commands give the full picture:

```bash
./bin/status
./bin/logs
./bin/logs --debug
./bin/wp ability list
./bin/test --skip-claude
docker compose config
```

A failure in the MCP Adapter or MS WP Abilities themselves, not in this wiring,
belongs upstream:

- https://github.com/WordPress/mcp-adapter/issues
- https://github.com/miriamschwab/ms-wp-abilities/issues
