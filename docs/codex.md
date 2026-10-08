# Connecting OpenAI Codex

Codex reads root [AGENTS.md](../AGENTS.md) automatically. The project MCP config
is [`.codex/config.toml`](../.codex/config.toml), and it loads only when this
directory is **trusted**.

## Short version

```bash
./bin/setup
eval "$(./bin/connect --print | grep '^export ')"
codex          # from the repository root; trust the project when prompted
```

`./bin/connect --print` does not need Claude Code. It prints the MCP URL and an
`export WORDPRESS_MCP_BASIC_AUTH='Basic …'` line: the full `Authorization`
header value that `.codex/config.toml` reads from the environment.

## Tracked vs secret

| Piece | Where |
|-------|--------|
| MCP URL + header env mapping | `.codex/config.toml` (tracked) |
| Application Password / Basic value | `.secrets/` and your shell env (never committed) |
| Agent guidance | `AGENTS.md`, `docs/AGENTS.md`, `llms.txt` |

If you change `WP_PORT` in `.env`, update the `url` in `.codex/config.toml` to
match. `./bin/connect --print` shows the live URL.

## Verify

In a Codex session from this repository, run `/mcp`, or ask the agent to
discover WordPress abilities through the `wordpress` server. To check without
MCP: `./bin/wp ability list`.

## Claude Code and Cursor

- Claude Code: `./bin/connect`, then `claude` ([claude-code.md](claude-code.md)).
- Cursor: same skills under `.cursor/skills/`. Register an HTTP MCP server in
  Cursor's settings with the URL and header from `./bin/connect --print`.
- Shared map: [ai-skills.md](ai-skills.md).
