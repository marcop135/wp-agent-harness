# Development

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

This is the diagnostic path that skips MCP entirely — if something works here
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
`./bin/reset` still works — the bind-mounted directory is yours, not the
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

Procedure:

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
WP-CLI changes are picked up by the rebuild `./bin/setup` runs. A **MariaDB major
version** change needs `./bin/reset`, because the data directory format changes.

Before pinning a new upstream version, check its requirements — both plugins
currently need WordPress 6.9+ and PHP 7.4+, and the ability names this repository
asserts in `tests/smoke.sh` come from the pinned MS WP Abilities release. If
upstream renames one, that test fails, which is the point.

## Changing this repository

```bash
bash -n bin/* tests/*.sh          # syntax
shellcheck bin/* tests/*.sh       # if you have it; CI runs it
docker compose config --quiet     # compose validity
./bin/test --skip-claude          # layers 1-3
./bin/test claude-code            # layer 4, costs model turns
./bin/reset --yes && ./bin/test --skip-claude   # prove a clean build still works
```

CI runs the same checks plus a full stack build on Ubuntu, so a change that only
works on your machine fails there.

Conventions worth keeping:

- Every `bin/` script sources `bin/lib.sh` and nothing else.
- Anything that has to know a container path goes through `wpx`, which is the
  only place `MSYS_NO_PATHCONV` is set.
- Never `curl -o /dev/null`; use `http_status` or `http_headers` from
  `bin/lib.sh`. Git Bash's native curl treats `/dev/null` as a filename.
- Provisioning steps check current state before changing it. Setup must stay
  idempotent.
- Tests name their content uniquely and delete it in an `EXIT` trap.
