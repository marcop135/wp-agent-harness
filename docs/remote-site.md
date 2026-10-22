# Connecting an agent to a live site

The MCP path this harness uses locally works against any WordPress site with the
same plugins: same endpoint, same Application Password auth, same three
meta-tools.

**This leaves the harness behind.** No `bin/` script and no test layer touches a
remote site. There is no `./bin/reset`, no pinned stack, and nothing is
disposable: every ability call is a real change on a real site, and the MCP
endpoint is reachable from the internet. The [security model](security.md)
applies in full.

## What the site needs

| Requirement | Why |
|-------------|-----|
| WordPress 6.9 or later | Abilities API in core |
| [MCP Adapter](https://github.com/WordPress/mcp-adapter) active | the MCP endpoint |
| [MS WordPress Abilities](https://github.com/miriamschwab/ms-wp-abilities) active, or another abilities plugin | the abilities |
| Pretty permalinks (anything but Plain) | with Plain, `/wp-json/` does not resolve, REST answers only on `?rest_route=`, and MCP clients do not find the server |
| HTTPS | core offers Application Passwords only over HTTPS, or on plain HTTP when `WP_ENVIRONMENT_TYPE` is `local`; do not set `local` on a live site to get around this |

## Auth

1. Create a dedicated WordPress user for the agent with the lowest role the work
   needs: Editor for content, Administrator only for plugins or settings.
   Abilities run with that user's capabilities.
2. Under **Users → Profile**, create an Application Password for it. Revoke it
   when the work is done.
3. Build the header value, `Basic <base64 of username:application-password>`,
   without putting it in shell history on a shared machine:

   ```bash
   read -rs -p 'username:application-password: ' creds; echo
   printf 'Basic %s\n' "$(printf '%s' "$creds" | base64 | tr -d '\r\n')"; unset creds
   ```

The endpoint is:

```text
https://<site>/wp-json/mcp/mcp-adapter-default-server
```

| Host setup that breaks auth | Fix |
|-----------------------------|-----|
| Host-level HTTP Basic Auth (directory protection, staging password). It uses the same `Authorization` header, so WordPress reports Application Passwords as unavailable and the client cannot pass the host gate. | Turn host auth off for the site, or exempt `/wp-json/` from it. |
| Apache with PHP as CGI/FastCGI drops the `Authorization` header. WordPress's `.htaccess` block (5.6 and later) restores it with `RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]`; without that line every authenticated request returns 401. | Restore the WordPress block, or add `SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1` above it. |
| Security plugin or host WAF blocking REST or Application Passwords | Check their logs when a correct header still returns 401 or 403. |

## Wire the client

Register the live site as `wordpress-live`, never as `wordpress` and never from
this directory: this repository's agent instructions describe `wordpress` as a
disposable local site.

Claude Code, from a directory other than this repository:

```bash
claude mcp add --transport http --scope local wordpress-live \
  'https://<site>/wp-json/mcp/mcp-adapter-default-server' \
  --header "Authorization: Basic <base64>"
```

Cursor, in `~/.cursor/mcp.json`, reading the secrets from user environment
variables (restart Cursor after setting them):

```json
{
  "mcpServers": {
    "wordpress-live": {
      "url": "${env:WORDPRESS_LIVE_MCP_URL}",
      "headers": { "Authorization": "${env:WORDPRESS_LIVE_MCP_BASIC_AUTH}" }
    }
  }
}
```

Codex, in `~/.codex/config.toml` (this repository's `.codex/config.toml` is the
local server):

```toml
[mcp_servers.wordpress-live]
url = "https://<site>/wp-json/mcp/mcp-adapter-default-server"
env_http_headers = { Authorization = "WORDPRESS_LIVE_MCP_BASIC_AUTH" }
```

`./bin/connect --print` shows the same shape for the local site.

## Check the connection

1. `GET https://<site>/wp-json/` returns JSON with `mcp` in `namespaces`. A
   site that limits REST to logged-in users answers 401 `rest_cannot_access`
   without auth; send the auth header for this check.
2. MCP `initialize` without auth returns 401, so the endpoint is protected.
3. `initialize` with auth returns an `Mcp-Session-Id` header. Later requests
   carry it plus `MCP-Protocol-Version`; without the version header the adapter
   rejects the request. Handshake: [architecture.md](architecture.md#mcp-transport);
   curl sequence: [development.md](development.md).
4. `tools/list` returns the three meta-tools.
5. `mcp-adapter-execute-ability` with `core/get-site-info` returns the live site
   name and version.

If an ability works in wp-admin or WP-CLI on the server but not over MCP, the
problem is transport or credentials, not the ability.

## Ask before every write

Every write here is a real change. `bin/ability-gate` makes the client ask
before any write ability and lets reads through
([how it works](security.md#the-approval-gate)). Wire it into the client config
you use for the live site, pointing at your clone of this repository.

Claude Code, in `~/.claude/settings.json` or the project you run it from
(`wordpress-live` is the server name registered above):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__wordpress-live__mcp-adapter-execute-ability",
        "hooks": [
          { "type": "command", "command": "bash /path/to/wp-agent-harness/bin/ability-gate claude", "timeout": 10 }
        ]
      }
    ]
  }
}
```

Cursor, in `~/.cursor/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "beforeMCPExecution": [
      { "command": "bash /path/to/wp-agent-harness/bin/ability-gate cursor", "timeout": 10, "failClosed": true }
    ]
  }
}
```

The gate needs `bash` and `jq`. Its read list follows MS WP Abilities, so an
ability from another plugin always asks. On a site with MS WP Abilities 1.11 or
later, the plugin's audit log records every write call; read it on the server
with `wp option get mswpa_write_log --format=json`.

## Working on a live site

- Read first, then change. Drafts by default.
- Nothing that resets, bulk-deletes or reinstalls.
- Back the site up before plugin or theme work.
- A `robots.txt` that disallows crawlers is a request, not access control. To
  keep a site private, use a login gate inside WordPress (a plugin such as
  Password Protected) rather than host-level Basic Auth: Application Password
  requests count as logged in, so MCP keeps working.
