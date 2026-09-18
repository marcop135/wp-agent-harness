# Connecting Claude Code

## The short version

```bash
./bin/connect
cd /path/to/wordpress-claude-mcp && claude
```

## The registration

| | |
|---|---|
| Server name | `wordpress` (`MCP_SERVER_NAME` in `.env`) |
| Transport | `http` |
| URL | `http://localhost:8080/wp-json/mcp/mcp-adapter-default-server` |
| Authentication | `Authorization: Basic <base64 of admin:application-password>` |
| Scope | `local` — this project only, stored in `~/.claude.json` |

`./bin/connect` is exactly this, with the endpoint and credential filled in from
`.env` and `.secrets/application-password`:

```bash
claude mcp add --transport http --scope local \
  wordpress \
  http://localhost:8080/wp-json/mcp/mcp-adapter-default-server \
  --header "Authorization: Basic YWRtaW46..."
```

It removes any existing registration of the same name first, so re-running it
after `./bin/reset` picks up the new Application Password instead of leaving a
stale one behind.

To see what it would write without writing anything:

```bash
./bin/connect --print
```

## Scopes

Claude Code has three:

| Scope | Applies to | Stored in |
|-------|------------|-----------|
| `local` (used here) | this project, this user | `~/.claude.json`, under the project's path |
| `project` | this project, shared via version control | `.mcp.json` in the repository root |
| `user` | every project | `~/.claude.json`, top level |

`local` is the right one here. It is already project-scoped, and it keeps the
Application Password out of the repository. `project` scope would put a tracked
`.mcp.json` next to the code; since the credential cannot go in it, it would
need an environment-variable indirection:

```json
{
  "mcpServers": {
    "wordpress": {
      "type": "http",
      "url": "${WORDPRESS_MCP_URL:-http://localhost:8080/wp-json/mcp/mcp-adapter-default-server}",
      "headers": { "Authorization": "Basic ${WORDPRESS_MCP_BASIC_AUTH}" }
    }
  }
}
```

That works — `.mcp.json` expands `${VAR}` and `${VAR:-default}` in `url`,
`headers`, `command`, `args` and `env` — but it means exporting
`WORDPRESS_MCP_BASIC_AUTH` in every shell that starts Claude Code, and it adds a
file whose only purpose is to reference a secret stored elsewhere. `.mcp.json` is
in `.gitignore` here so an experiment cannot be committed by accident.

## Verifying the connection

```bash
claude mcp list
claude mcp get wordpress
```

A working registration reads:

```
wordpress:
  Scope: Local config (private to you in this project)
  Status: ✔ Connected
  Type: http
  URL: http://localhost:8080/wp-json/mcp/mcp-adapter-default-server
  Headers:
    Authorization: Basic ...
```

Run both from the repository directory — a `local`-scope server does not exist
anywhere else.

Inside an interactive session, `/mcp` lists the connected servers and their
tools. You should see three:

```
mcp__wordpress__mcp-adapter-discover-abilities
mcp__wordpress__mcp-adapter-get-ability-info
mcp__wordpress__mcp-adapter-execute-ability
```

Three is correct and complete. The abilities live behind them — see
[architecture.md](architecture.md#why-three-tools-and-not-thirty).

The end-to-end check, which drives a real headless session:

```bash
./bin/test claude-code
```

## Removing the connection

```bash
./bin/connect --remove       # or: claude mcp remove wordpress -s local
```

This only unregisters the server. WordPress keeps running and the Application
Password stays valid; to revoke that too, delete it in
**Users → Profile → Application Passwords**, or:

```bash
docker compose exec -T wordpress wp-app-password delete
rm .secrets/application-password
```

## Using it headlessly

Every `./bin/test claude-code` step is a single non-interactive turn:

```bash
claude -p "Using the WordPress MCP server, list the active plugins." \
  --output-format json \
  --allowedTools "mcp__wordpress" \
  --permission-prompts none
```

`--allowedTools "mcp__wordpress"` permits the whole server; `--permission-prompts
none` denies anything that would otherwise prompt, so the turn cannot hang.

## Troubleshooting

**`claude mcp get wordpress` says the server is not found.**
You are not in the repository directory, or `./bin/connect` has not run. `local`
scope is keyed to the project path.

**Status is not `Connected`.**
Check the stack first: `./bin/start`, then `./bin/status`. If `./bin/status`
reports an authenticated `initialize`, the endpoint is fine and the problem is
the registration — re-run `./bin/connect`.

**Claude Code connects but has no WordPress tools.**
Restart the session. Claude Code reads the MCP configuration at start, so a
server registered mid-session is not picked up.

**Tools appear but every call fails with an authentication error.**
The Application Password was rotated (`./bin/reset`, or a manual revoke) while
the old one is still in `~/.claude.json`. `./bin/setup && ./bin/connect`, then
restart Claude Code.

**The port changed.**
The registered URL still points at the old one. `./bin/connect` again.

More, including the WordPress-side failures: [troubleshooting.md](troubleshooting.md).
