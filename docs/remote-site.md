# Connecting an agent to a live site

The MCP path this harness uses locally works against any WordPress site with the
same plugins: same endpoint, same Application Password auth, same three
meta-tools. This page covers pointing an agent at a live (remote) site.

**This leaves the harness behind.** None of `bin/` and none of the test layers
touch a remote site. There is no `./bin/reset`, no pinned stack, and nothing is
disposable: every ability call is a real change on a real site. The
[security model](security.md) applies in full, and the MCP endpoint is now
reachable from the internet.

## What the site needs

- WordPress 6.9 or later (Abilities API in core).
- [MCP Adapter](https://github.com/WordPress/mcp-adapter) active.
- [MS WordPress Abilities](https://github.com/miriamschwab/ms-wp-abilities)
  active, or another abilities plugin.
- Pretty permalinks (anything but Plain). With Plain permalinks `/wp-json/` does
  not resolve, REST answers only on `?rest_route=`, and MCP clients do not find
  the server.
- HTTPS. Core offers Application Passwords only over HTTPS, or on plain HTTP when
  `WP_ENVIRONMENT_TYPE` is `local`. Do not set `local` on a live site to get
  around this.

## Auth

Create a dedicated WordPress user for the agent, with the lowest role the work
needs (Editor for content work; Administrator only when the task is plugins or
settings). Abilities run with that user's capabilities. Under Users → Profile,
create an Application Password for it, and revoke it when the work is done.

The MCP endpoint is:

```text
https://<site>/wp-json/mcp/mcp-adapter-default-server
```

The client sends `Authorization: Basic <base64 of username:application-password>`.
Build the value without putting it in shell history on a shared machine:

```bash
read -rs -p 'username:application-password: ' creds; echo
printf 'Basic %s\n' "$(printf '%s' "$creds" | base64 | tr -d '\r\n')"; unset creds
```

Two host setups break this:

- **Host-level HTTP Basic Auth** (directory protection, staging password).
  It uses the same `Authorization` header, so one request cannot carry both.
  WordPress reports Application Passwords as unavailable, and the client cannot
  get past the host gate. Turn host auth off for the site, or exempt
  `/wp-json/` from it.
- **Apache with PHP as CGI/FastCGI** drops the `Authorization` header before
  PHP sees it. WordPress's own `.htaccess` block (5.6 and later) passes it back
  with `RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]`. An older
  or hand-edited `.htaccess` without that line makes every authenticated
  request return 401; restore the WordPress block, or add this above it:

  ```apache
  SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1
  ```

Security plugins and host WAFs sometimes block REST or Application Passwords
too; check their logs when a correct header still returns 401 or 403.

## Wire the client

Keep the remote server separate from the local one. This repository's agent
instructions describe the `wordpress` server as a disposable local site, so do
not register the live site under that name or from this directory.

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
   rejects the request. See the handshake in
   [architecture.md](architecture.md#mcp-transport) and the curl sequence in
   [development.md](development.md).
4. `tools/list` returns the three meta-tools.
5. `mcp-adapter-execute-ability` with `core/get-site-info` returns the live site
   name and version.

If an ability works in wp-admin or WP-CLI on the server but not over MCP, the
problem is transport or credentials, not the ability.

## Working on a live site

Read first, then change. Drafts by default. Nothing that resets, bulk-deletes or
reinstalls. Back the site up before plugin or theme work.

A `robots.txt` that disallows crawlers is a request, not access control. To keep
a site private, use a login gate inside WordPress (a plugin such as Password
Protected) rather than host-level Basic Auth: Application Password requests
count as logged in, so MCP keeps working.
