# Connecting OpenAI Codex

Codex reads root [AGENTS.md](../AGENTS.md) automatically. Project MCP lives in
[`.codex/config.toml`](../.codex/config.toml) and loads only when this directory
is **trusted**.

## Short version

```bash
./bin/setup
eval "$(./bin/connect --print | grep '^export ')"
codex          # from this repository root; trust the project when prompted
```

`./bin/connect --print` does not need Claude Code on PATH. It prints the MCP URL
and an `export WORDPRESS_MCP_BASIC_AUTH='Basic …'` line. That env var is the
full `Authorization` header value referenced by `.codex/config.toml`.

## What is tracked vs secret

| Piece | Where |
|-------|--------|
| MCP URL + header env mapping | `.codex/config.toml` (tracked) |
| Application Password / Basic value | `.secrets/` + your shell env (never committed) |
| Agent guidance | `AGENTS.md`, `docs/AGENTS.md`, `llms.txt` |

If you change `WP_PORT` in `.env`, edit the `url` in `.codex/config.toml` to
match (`./bin/connect --print` shows the live URL).

## Verify

In a Codex session from this repo:

```text
/mcp
```

or ask the agent to discover WordPress abilities through the `wordpress` MCP
server. Diagnostic path without MCP: `./bin/wp ability list`.

## Claude Code and Cursor

- Claude Code: `./bin/connect` then `claude` ([claude-code.md](claude-code.md)).
- Cursor: same skills under `.cursor/skills/`, same MCP URL/auth from
  `./bin/connect --print`; register the HTTP server in Cursor MCP settings.
- Shared map: [ai-skills.md](ai-skills.md).
