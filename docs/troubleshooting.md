# Troubleshooting

Start with `./bin/status`. It walks the stack in order — containers, WordPress,
abilities, MCP endpoint, Claude Code registration — and the first failing check
tells you which layer to read about below.

```
WordPress works  →  abilities work  →  MCP works  →  Claude Code works
 ./bin/status       ./bin/wp ability   tests/         tests/
                    list               integration.sh claude-code.sh
```

If `./bin/wp ability run core/get-site-info --user=admin` works but MCP does
not, the fault is in the MCP or authentication layer, not in WordPress.

---

## Docker

### `The Docker daemon is not running`

```bash
docker info
```

macOS / Windows: start Docker Desktop and wait for the whale to settle.
Linux: `sudo systemctl start docker`.

### `docker compose (v2) is unavailable`

```bash
docker compose version    # must print v2.x or later
```

Compose v1 (`docker-compose`, with a hyphen) is not supported. Install the
Compose plugin, or update Docker Desktop.

### `docker: permission denied` on Linux

Add yourself to the `docker` group and start a new login shell:

```bash
sudo usermod -aG docker "$USER"
```

---

## Ports

### `127.0.0.1:8080 is already in use by something else`

Find the holder:

```bash
# macOS / Linux
lsof -nP -iTCP:8080 -sTCP:LISTEN
# Windows
netstat -ano -p tcp | grep ':8080 .*LISTENING'
```

Then either stop it, or move this project:

```bash
sed -i.bak 's/^WP_PORT=.*/WP_PORT=8081/' .env    # or edit .env by hand
./bin/start
./bin/connect          # the registered MCP URL still points at the old port
```

No reinstall is needed — `WP_HOME` reads the port from the container's
environment at runtime.

The same applies to `DB_PORT`; 3307 is the default precisely because a local
MySQL usually holds 3306.

---

## Database

### The `db` container never becomes healthy

```bash
./bin/logs db
docker compose ps
```

Common causes:

- **Changed `MYSQL_PASSWORD` or `MYSQL_USER` after the first run.** The volume
  still holds the old credentials; the image only applies them on an empty data
  directory. Fix: `./bin/reset`.
- **A corrupt volume** after an abrupt shutdown. Fix: `./bin/reset`.
- **Not enough memory.** Raise Docker Desktop's memory limit to 4 GB or more.

### `Error establishing a database connection`

The WordPress container starts before MariaDB finishes its first-run
initialisation on a cold volume. `depends_on: service_healthy` handles this; if
you see it anyway:

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

If the container is healthy but curl times out, something on the host is
intercepting loopback traffic — a VPN in full-tunnel mode is the usual culprit.

### `./bin/setup` fails during `wp core install`

```bash
./bin/logs wordpress
./bin/wp db check
./bin/wp core version
```

An install that got half-way leaves the database in a state
`wp core is-installed` rejects. `./bin/reset` is the reliable fix; nothing here
is precious.

### `/wp-json/` returns 404

Pretty permalinks are not being rewritten. Provisioning fails loudly on this,
but to check by hand:

```bash
docker compose exec wordpress cat /var/www/html/.htaccess
docker compose exec wordpress apache2ctl -M | grep rewrite
./bin/wp option get permalink_structure       # expects /%postname%/
./bin/wp rewrite flush
```

`docker/wordpress/apache-wordpress.conf` sets `AllowOverride All`; if you edited
it, `./bin/setup` rebuilds the image.

The fallback, if you need to reach the API while diagnosing this, is
`http://localhost:8080/?rest_route=/`.

---

## Plugins

### A plugin fails to install

```bash
./bin/logs wordpress
docker compose exec wordpress curl -sI \
  https://github.com/WordPress/mcp-adapter/releases/download/v0.6.1/mcp-adapter.zip
```

The ZIPs come from GitHub release assets. A download failure is almost always
the network — a proxy, a corporate TLS interceptor, or a VPN that geo-blocks the
host. Check the URL resolves *from inside the container*, which is where the
download happens.

Retry by hand:

```bash
./bin/wp plugin install \
  https://github.com/WordPress/mcp-adapter/releases/download/v0.6.1/mcp-adapter.zip --force
```

A wrong `MCP_ADAPTER_VERSION` or `MS_WP_ABILITIES_VERSION` in `.env` gives a 404.
The ms-wp-abilities asset name includes the version:
`ms-wp-abilities-<version>.zip`.

### A plugin installs but will not activate

```bash
./bin/wp plugin activate mcp-adapter --debug
./bin/logs --debug
```

Both plugins require WordPress 6.9+ and PHP 7.4+:

```bash
./bin/wp core version
docker compose exec wordpress php -v
```

MS WP Abilities also needs MCP Adapter active first. Provisioning installs them
in that order; if you are doing it by hand, keep it.

---

## Abilities

### `wp ability` is not a registered command

The command comes from `wp-cli/ability-command`, baked into the image:

```bash
docker compose exec wordpress cat /usr/local/etc/wp-cli.yml
docker compose exec wordpress ls /usr/local/lib/wp-cli-packages/ability-command
./bin/wp --info
```

If the directory is missing or empty the image is stale. Rebuild:

```bash
docker compose build --no-cache wordpress && ./bin/start
```

### `wp ability list` returns nothing

```bash
./bin/wp plugin list
./bin/wp eval 'var_dump( function_exists( "wp_register_ability" ) );'
```

`false` means WordPress is older than 6.9 — check `WORDPRESS_IMAGE` in `.env`.
`true` with an empty list means ms-wp-abilities is inactive.

### An ability is registered but does not appear over MCP

Abilities are private by default; only `meta.public` or `meta.mcp.public`
exposes them. Compare the two lists:

```bash
./bin/wp ability list --field=name | sort > /tmp/registered
./bin/wp ability get miriamschwab/get-posts --fields=name,meta
```

**Tools → WP Abilities** in wp-admin shows the MCP-public flag for every
ability on the site, which is faster than reading source.

### An ability execution fails

The MCP response carries `isError: true` and the WordPress error message. Run
the same ability without MCP to see whether the fault is in the ability or the
transport:

```bash
./bin/wp ability can-run miriamschwab/create-post --user=admin
./bin/wp ability validate miriamschwab/create-post --input='{"title":"x"}'
./bin/wp ability run miriamschwab/get-posts --input='{"per_page":1}' --user=admin
./bin/logs --debug
```

`permission_denied` means the user lacks the capability the ability requires —
`edit_posts` for content, `activate_plugins` for plugin work. Check
`WP_ADMIN_USER` really is an administrator:

```bash
./bin/wp user list --fields=user_login,roles
```

---

## MCP endpoint

### 404 at `/wp-json/mcp/mcp-adapter-default-server`

```bash
./bin/wp plugin is-active mcp-adapter && echo active
curl -s http://localhost:8080/wp-json/ | grep -o '"mcp[^"]*"' | head
./bin/wp rewrite flush
```

An inactive MCP Adapter, or unflushed rewrite rules. `./bin/setup` fixes both.

### 401 with the right credential

```bash
./bin/wp user application-password list admin
docker compose exec -T wordpress wp-app-password available   # expects exit 0
curl -s -u "admin:$(cat .secrets/application-password)" \
  http://localhost:8080/wp-json/wp/v2/users/me
```

- `wp-app-password available` failing means WordPress does not consider the site
  local. Check `WP_ENVIRONMENT_TYPE`:
  ```bash
  ./bin/wp eval 'echo wp_get_environment_type();'     # expects: local
  ```
- `/wp/v2/users/me` returning 401 while the password is correct means Apache is
  not passing the `Authorization` header to PHP. The image handles this in two
  places — `docker/wordpress/apache-wordpress.conf` and the `.htaccess` rewrite —
  so check both survive:
  ```bash
  docker compose exec wordpress grep -r Authorization /etc/apache2/conf-enabled/
  docker compose exec wordpress grep Authorization /var/www/html/.htaccess
  ```
- If the password was rotated, re-issue and re-register:
  ```bash
  rm .secrets/application-password && ./bin/setup && ./bin/connect
  ```

### `Missing Mcp-Session-Id header`

Your client is not doing the handshake. Every request after `initialize` must
carry the `Mcp-Session-Id` the initialize response returned. Claude Code does
this automatically; hand-rolled curl does not. See
[architecture.md](architecture.md#mcp-transport), or read
`mcp_request()` in `tests/lib.sh` for a 20-line reference implementation.

### `Invalid or expired session`

Sessions expire after a day of inactivity, and each user keeps at most 32. Start
a new one — `initialize` again.

### `GET` returns 405

Expected. The adapter has not implemented SSE streaming; the endpoint is
POST/DELETE only.

---

## Claude Code

### `claude mcp get wordpress` finds nothing

Run it from the repository directory. The registration is `local` scope, keyed
to the project path. If you are in the right place, `./bin/connect`.

### Connected, but no WordPress tools in the session

Claude Code reads MCP configuration at start. Restart the session.

### Tools are there but every call fails

Almost always a rotated Application Password — `./bin/reset` issues a new one and
the old one is still in `~/.claude.json`:

```bash
./bin/setup && ./bin/connect
```

Then restart Claude Code. Confirm the endpoint independently first:

```bash
./bin/status
./bin/test integration
```

### Only three tools are listed

Correct. `mcp-adapter-discover-abilities`, `mcp-adapter-get-ability-info` and
`mcp-adapter-execute-ability` are the whole public surface; the 29 abilities sit
behind them. See
[architecture.md](architecture.md#why-three-tools-and-not-thirty).

### The port changed and calls stopped working

The registered URL still points at the old port. `./bin/connect` rewrites it,
then restart Claude Code.

### `./bin/connect` fails with `claude is not on PATH`

Claude Code is not installed, or not in this shell's `PATH`. `./bin/setup` warns
about it rather than failing — everything except `./bin/connect` and test layer 4
works without it.

---

## Permissions and file ownership

### Uploads or plugin installs fail with a filesystem error

WordPress owns `/var/www/html` as `www-data`. `./bin/wp` drops to that user
precisely so WP-CLI does not leave root-owned files behind. If something else
did:

```bash
docker compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content
```

### `bin/*: Permission denied` after cloning

Git did not preserve the executable bit (some Windows configurations):

```bash
chmod +x bin/* tests/*.sh docker/wordpress/bin/*
```

Or invoke through bash: `bash bin/setup`.

---

## Stale volumes and resetting

### Changes to `.env` seem to have no effect

Values consumed at **install** time — `MYSQL_USER`, `MYSQL_PASSWORD`,
`MYSQL_DATABASE` — are baked into the volume on first run. Values consumed at
**provision** time — `WP_SITE_TITLE`, `WP_ADMIN_PASSWORD`, `WP_THEME`, the
version pins — are re-applied by `./bin/setup`. `WP_PORT` is read at runtime.

If a database credential changed, only `./bin/reset` will do.

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
docker image rm wordpress-claude-mcp-wordpress:local
docker builder prune
```

---

## Changing local credentials

**Administrator password** — edit `WP_ADMIN_PASSWORD` in `.env`, then
`./bin/setup`. Provisioning synchronises it.

**Database passwords** — edit `.env`, then `./bin/reset`. There is no way to
change them in place; the volume holds the old ones.

**Application Password** — rotate and re-register:

```bash
rm .secrets/application-password
./bin/setup
./bin/connect
```

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

Those six give the full picture. If the failure is in the MCP Adapter or MS WP
Abilities rather than in this wiring, it belongs upstream:

- https://github.com/WordPress/mcp-adapter/issues
- https://github.com/miriamschwab/ms-wp-abilities/issues
