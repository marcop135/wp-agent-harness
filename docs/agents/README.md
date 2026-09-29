# Agent workflow (cross-tool)

Editor-agnostic contracts for AI agents working in this harness. File layout: canonical `docs/AGENTS.md`, root `AGENTS.md` mirror, `CLAUDE.md`, `.cursor/AGENTS.md`, `.codex/config.toml`.

| Doc | Purpose |
| --- | --- |
| [agent-contract.md](agent-contract.md) | Task template, git/changelog expectations, verification, cross-tool parity |
| [runtime-policy.md](runtime-policy.md) | Risk tiers; when to auto-run vs confirm |
| [AI skills map](../ai-skills.md) | Entry docs vs MCP vs coding skills |
| [Codex](../codex.md) | Codex trust + `.codex/config.toml` + env auth |
| [../AGENTS.md](../AGENTS.md) | Full docs index, commands, condensed domain rules |

**Repo root:** [`AGENTS.md`](../../AGENTS.md) mirrors the index for tools that only load root `AGENTS.md` (including Codex).

**Claude Code:** [`CLAUDE.md`](../../CLAUDE.md). MCP registration and scopes: [`../claude-code.md`](../claude-code.md).

**Cursor agent (IDE):** precedence in [`.cursor/AGENTS.md`](../../.cursor/AGENTS.md).

**OpenAI Codex:** [`.codex/config.toml`](../../.codex/config.toml) + [`../codex.md`](../codex.md).

**Project skills (Claude / Cursor):** [`.claude/skills/`](../../.claude/skills/) and [`.cursor/skills/`](../../.cursor/skills/) (same curated WordPress set).

## Tool loading matrix

| Tool | Entry files | Skills / MCP |
| --- | --- | --- |
| Claude Code | `CLAUDE.md`, root `AGENTS.md` | `.claude/skills/`; `./bin/connect` |
| Cursor IDE | root `AGENTS.md`, `.cursor/AGENTS.md` | `.cursor/skills/`; MCP from `--print` |
| Cursor CLI | root `AGENTS.md`, `CLAUDE.md` | `.cursor/skills/` / `.claude/skills/` |
| Codex | root `AGENTS.md`, `.codex/config.toml` | MCP via `WORDPRESS_MCP_BASIC_AUTH` |