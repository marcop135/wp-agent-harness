# AI skills in this harness

Three surfaces agents use here. Do not conflate them.

| Path | Audience | Role |
| --- | --- | --- |
| `llms.txt`, `AGENTS.md`, `docs/AGENTS.md`, `CLAUDE.md`, `.cursor/AGENTS.md` | Any coding agent (Claude Code, Cursor, Codex, …) | How to work in this repository: MCP loop, drafts-by-default, infra vs site, commands |
| `wordpress` MCP / `./bin/wp` | Site work | Drive the local WordPress install (discover → schema → execute, or WP-CLI abilities) |
| `.claude/skills/` and `.cursor/skills/` | WordPress coding | Curated [WordPress/agent-skills](https://github.com/WordPress/agent-skills) for blocks, themes, plugins, REST, Abilities API, WP-CLI |
| `.codex/config.toml` | OpenAI Codex | Project MCP URL + `WORDPRESS_MCP_BASIC_AUTH` env header (see [codex.md](codex.md)) |

This harness does **not** ship an installable consumer skill CLI (unlike a design-system `skills install` flow). The skills pack is already in the clone. Site ops stay on MCP and `./bin/wp`; the coding skills do not replace that stack.

## Agent entry

Start at [llms.txt](../llms.txt) or [docs/AGENTS.md](AGENTS.md). Task shape and risk tiers: [agents/](agents/).

| Client | MCP wiring |
| --- | --- |
| Claude Code | `./bin/connect` then `claude` ([claude-code.md](claude-code.md)) |
| Codex | trust project, `eval "$(./bin/connect --print \| grep '^export ')"`, then `codex` ([codex.md](codex.md)) |
| Cursor | skills under `.cursor/skills/`; HTTP MCP from `./bin/connect --print` in Cursor settings |

## Coding skills

Skill table, what is intentionally omitted (`wp-env`, Playground, Blueprints), and how to refresh from upstream: [claude-code.md](claude-code.md#wordpress-agent-skills).

Keep `.claude/skills/` and `.cursor/skills/` in sync. After a refresh, confirm discovery with `claude /skills` or Cursor's skill list from the repository root.

## Precedence

1. Explicit user instruction for this session.
2. [docs/AGENTS.md](AGENTS.md) / [CLAUDE.md](../CLAUDE.md) / [.cursor/AGENTS.md](../.cursor/AGENTS.md).
3. Coding skills under `.claude/skills/` / `.cursor/skills/` for WordPress code patterns.
4. Model memory last. Discover abilities at runtime.
