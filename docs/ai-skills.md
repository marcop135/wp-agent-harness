# AI skills in this harness

Agents use four separate surfaces here. Keep them apart.

| Path | For | Role |
| --- | --- | --- |
| `llms.txt`, `AGENTS.md`, `docs/AGENTS.md`, `CLAUDE.md`, `.cursor/AGENTS.md` | Any coding agent (Claude Code, Cursor, Codex, …) | How to work in this repository: MCP loop, drafts by default, infra vs site, commands |
| `wordpress` MCP / `./bin/wp` | Site work | Drive the local WordPress install (discover → schema → execute, or WP-CLI abilities) |
| `.claude/skills/`, `.cursor/skills/` | WordPress coding | Curated [WordPress/agent-skills](https://github.com/WordPress/agent-skills): blocks, themes, plugins, REST, Abilities API, WP-CLI |
| `.codex/config.toml` | OpenAI Codex | Project MCP URL + `WORDPRESS_MCP_BASIC_AUTH` header ([codex.md](codex.md)) |

There is no skill installer to run: the skills are already in the clone. Site
work stays on MCP and `./bin/wp`; the coding skills do not replace them.

## Agent entry

Start at [llms.txt](../llms.txt) or [docs/AGENTS.md](AGENTS.md). Task shape and
risk tiers: [agents/](agents/).

| Client | MCP wiring |
| --- | --- |
| Claude Code | `./bin/connect`, then `claude` ([claude-code.md](claude-code.md)) |
| Codex | trust the project, `eval "$(./bin/connect --print \| grep '^export ')"`, then `codex` ([codex.md](codex.md)) |
| Cursor | skills under `.cursor/skills/`; HTTP MCP from `./bin/connect --print` in Cursor settings |

## Coding skills

The skill table, what is left out on purpose (`wp-env`, Playground,
Blueprints) and how to refresh from upstream:
[claude-code.md](claude-code.md#wordpress-agent-skills).

Keep `.claude/skills/` and `.cursor/skills/` in sync. After a refresh, check
discovery with `claude /skills` or Cursor's skill list from the repository root.

## Precedence

1. Explicit user instruction for this session.
2. [docs/AGENTS.md](AGENTS.md) / [CLAUDE.md](../CLAUDE.md) / [.cursor/AGENTS.md](../.cursor/AGENTS.md).
3. Coding skills under `.claude/skills/` / `.cursor/skills/` for WordPress code patterns.
4. Model memory last. Discover abilities at runtime.
