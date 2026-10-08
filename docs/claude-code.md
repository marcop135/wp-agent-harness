# Connecting Claude Code

```bash
./bin/connect
claude          # from the repository root
```

Other clients: [Codex](codex.md). `./bin/connect --print` prints the URL and a
`WORDPRESS_MCP_BASIC_AUTH` export for any HTTP MCP client, without needing
Claude Code. How the pieces fit: [ai-skills.md](ai-skills.md).

## The registration

| | |
|---|---|
| Server name | `wordpress` (`MCP_SERVER_NAME` in `.env`) |
| Transport | `http` |
| URL | `http://localhost:8080/wp-json/mcp/mcp-adapter-default-server` |
| Authentication | `Authorization: Basic <base64 of admin:application-password>` |
| Scope | `local`: this project only, stored in `~/.claude.json` |

`./bin/connect` runs exactly this, filled in from `.env` and
`.secrets/application-password`:

```bash
claude mcp add --transport http --scope local \
  wordpress \
  http://localhost:8080/wp-json/mcp/mcp-adapter-default-server \
  --header "Authorization: Basic YWRtaW46..."
```

It removes an existing registration of the same name first, so re-running it
after `./bin/reset` picks up the new Application Password.

## Why `local` scope

| Scope | Applies to | Stored in |
|-------|------------|-----------|
| `local` (used here) | this project, this user | `~/.claude.json`, under the project's path |
| `project` | this project, shared via Git | `.mcp.json` in the repository root |
| `user` | every project | `~/.claude.json`, top level |

`local` is already project-scoped and keeps the Application Password out of the
repository. `project` scope would need a tracked `.mcp.json` that reads the
secret from the environment:

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

That works (`.mcp.json` expands `${VAR}` and `${VAR:-default}` in `url`,
`headers`, `command`, `args` and `env`), but every shell that starts Claude Code
then needs `WORDPRESS_MCP_BASIC_AUTH` exported. `.mcp.json` is in `.gitignore`
so an experiment cannot be committed by accident.

## Verify the connection

Run from the repository root; a `local`-scope server does not exist anywhere
else.

```bash
claude mcp list
claude mcp get wordpress
```

A working registration shows:

```
wordpress:
  Scope: Local config (private to you in this project)
  Status: ✔ Connected
  Type: http
  URL: http://localhost:8080/wp-json/mcp/mcp-adapter-default-server
  Headers:
    Authorization: Basic ...
```

In a session, `/mcp` lists exactly three tools. That is complete: the abilities
sit behind them ([why](architecture.md#why-three-tools-and-not-thirty)).

```
mcp__wordpress__mcp-adapter-discover-abilities
mcp__wordpress__mcp-adapter-get-ability-info
mcp__wordpress__mcp-adapter-execute-ability
```

End-to-end check with a real headless session: `./bin/test claude-code`.

## Headless use

Each `./bin/test claude-code` step is one non-interactive turn:

```bash
claude -p "Using the WordPress MCP server, list the active plugins." \
  --output-format json \
  --allowedTools "mcp__wordpress" \
  --permission-prompts none
```

`--allowedTools "mcp__wordpress"` allows the whole server. `--permission-prompts
none` denies anything that would prompt, so the turn cannot hang.

## WordPress agent skills

A curated subset of
[WordPress/agent-skills](https://github.com/WordPress/agent-skills)
(GPL-2.0-or-later) is vendored into `.claude/skills/` and `.cursor/skills/`, so
Claude Code and Cursor share one pack:

| Skill | Role |
|-------|------|
| `wordpress-router` | Classify the task and route to a domain skill |
| `wp-project-triage` | Detect project type, tooling, versions |
| `wp-block-development` | Gutenberg blocks |
| `wp-block-themes` | Block themes, `theme.json`, templates |
| `wp-patterns` | Block patterns |
| `wp-plugin-development` | Plugin architecture, hooks, security |
| `wp-rest-api` | REST routes, schema, auth |
| `wp-wpcli-and-ops` | WP-CLI and ops |
| `wp-abilities-api` | Abilities API registration and consumption |
| `wp-abilities-audit` | Audit REST surface for Abilities registrations |
| `wp-abilities-verify` | Verify Abilities registrations |

Left out on purpose: `wp-env`, `wp-playground`, `blueprint` and other skills
that compete with this repo's Docker and MCP stack. Site work stays on MCP
abilities and `./bin/wp` ([CLAUDE.md](../CLAUDE.md)). Agent index:
[AGENTS.md](AGENTS.md).

Refresh from upstream:

```bash
npx skills add WordPress/agent-skills \
  --skill wordpress-router \
  --skill wp-project-triage \
  --skill wp-block-development \
  --skill wp-block-themes \
  --skill wp-patterns \
  --skill wp-plugin-development \
  --skill wp-rest-api \
  --skill wp-wpcli-and-ops \
  --skill wp-abilities-api \
  --skill wp-abilities-audit \
  --skill wp-abilities-verify
```

Or clone upstream and run `skillpack-build.mjs` / `skillpack-install.mjs` with
`--targets=claude,cursor` and the same `--skills=` list. Confirm with
`claude /skills` (or Cursor's skill list) from the repository root.

## Remove the connection

```bash
./bin/connect --remove       # or: claude mcp remove wordpress -s local
```

This only unregisters the server. The Application Password stays valid; revoke
it under **Users → Profile → Application Passwords**, or:

```bash
docker compose exec -T wordpress wp-app-password delete
rm .secrets/application-password
```

## When it does not connect

[troubleshooting.md](troubleshooting.md#claude-code) covers the four failure
modes (server not found, status not `Connected`, connected but no tools, every
call failing) and their WordPress-side causes.
