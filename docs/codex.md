# Connecting Codex and Cursor

## Codex

Codex reads root [AGENTS.md](../AGENTS.md) automatically. The project MCP config
is [`.codex/config.toml`](../.codex/config.toml); it loads only when this
directory is **trusted**.

1. `./bin/setup` (once; creates the Application Password).
2. Export the auth header into the shell that starts Codex:

   ```bash
   eval "$(./bin/connect --print | grep '^export ')"
   ```

   `./bin/connect --print` does not need Claude Code. Its
   `export WORDPRESS_MCP_BASIC_AUTH='Basic …'` line is the full `Authorization`
   header value that `.codex/config.toml` reads from the environment.
3. `codex` from the repository root; trust the project when prompted.
4. Verify: `/mcp` in the session, or ask the agent to discover WordPress
   abilities through the `wordpress` server. Without MCP: `./bin/wp ability list`.

| Piece | Where |
|-------|--------|
| MCP URL + header env mapping | `.codex/config.toml` (tracked) |
| Application Password / Basic value | `.secrets/` and your shell env (never committed) |
| Agent guidance | `AGENTS.md`, `docs/AGENTS.md`, `llms.txt` |

- If you change `WP_PORT` in `.env`, update the `url` in `.codex/config.toml` to
  match. `./bin/connect --print` shows the live URL.
- **No approval gate.** Codex has no per-call hook in this repository; writes go
  through Codex's own approval policy
  ([security.md](security.md#the-approval-gate)).

## Claude Code and Cursor

Claude Code: `./bin/connect`, then `claude` ([claude-code.md](claude-code.md)).

### Cursor

1. `./bin/setup` (once), then `./bin/connect --print` for the URL and header.
2. In Cursor's MCP settings, add an HTTP server named `wordpress` with that
   `url` and the `Authorization: Basic …` header.
3. Open this repository as the workspace. Cursor reads
   [`.cursor/AGENTS.md`](../.cursor/AGENTS.md) and the skills under
   `.cursor/skills/` (the same pack as Claude Code's).
4. Verify: ask the agent to discover WordPress abilities; it should see the
   three `mcp-adapter-*` tools.

**Approval gate.** `.cursor/hooks.json` runs `bin/ability-gate cursor` as a
`beforeMCPExecution` hook before every MCP call, fail-closed. Reads pass; every
write ability asks you first, naming the ability. Project hooks run only in a
trusted workspace. Details: [security.md](security.md#the-approval-gate).

`./bin/connect --print` writes a live Basic auth header to stdout: do not paste
it into tickets or logs ([security.md](security.md#application-passwords)).

## Troubleshooting

Endpoint, auth, and ability failures are client-independent:
[troubleshooting.md](troubleshooting.md#mcp-endpoint). Shared map of agent
surfaces: [ai-skills.md](ai-skills.md).
