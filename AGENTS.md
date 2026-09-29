# Agents (wp-agent-harness)

Canonical narrative + tables: **[docs/AGENTS.md](docs/AGENTS.md)**.

This repo-root mirror exists for tools that only read `AGENTS.md` at the repository root. For the full documentation index, commands, and domain rules, open **[docs/AGENTS.md](docs/AGENTS.md)**.

**Maintenance:** When stack pins, commands, or skill triggers change, update this file together with [CLAUDE.md](CLAUDE.md) and [.cursor/AGENTS.md](.cursor/AGENTS.md). See [docs/agents/agent-contract.md](docs/agents/agent-contract.md) (Cross-tool parity).

## What this repo is

Local, disposable WordPress harness for coding agents. Docker Compose runs WordPress and MariaDB on loopback; agents talk to a real site over the official [WordPress MCP Adapter](https://github.com/WordPress/mcp-adapter). This repository does **not** ship an MCP server, abilities framework, or WordPress plugin of its own. Nothing here is public or production.

## Stack pin

```text
WordPress|7.1 (image wordpress:7.1.0-php8.3-apache) | PHP 8.3 | Apache 2.4
MariaDB|11.8.9
MCP Adapter|0.6.1 (GitHub release ZIP)
MS WordPress Abilities|1.12.0 (GitHub release ZIP)
WP-CLI|2.12.0 + ability-command 1.0.2
MCP|meta-tools: discover / get-ability-info / execute-ability
Ports|127.0.0.1 only (WP + DB)
```

Common mistakes:

- Inventing ability names or parameters instead of `discover` → `get-ability-info` → `execute`.
- Treating `docker-compose.yml` / `bin/` / `.env` as site content and editing them for a content task.
- Publishing, deleting, or bulk-changing without an explicit ask (default to drafts).
- Putting credentials in a tracked file, or binding ports to `0.0.0.0`.
- Switching the local site to `@wordpress/env`, Playground, or Blueprints.

## Commands (repo root)

| Task | Command |
| --- | --- |
| Provision (idempotent) | `./bin/setup` |
| Register MCP (Claude Code) | `./bin/connect` |
| Print MCP URL + auth export | `./bin/connect --print` (Codex / Cursor / any client) |
| Health | `./bin/status` |
| WP-CLI / abilities without MCP | `./bin/wp …` / `./bin/wp ability list` |
| Tests layers 0–3 | `./bin/test --skip-claude` |
| Destroy volumes | `./bin/reset` (explicit ask only) |

## Git and PR rules (summary)

- Branch from **`main`**. One subject per PR. Template: `.github/PULL_REQUEST_TEMPLATE.md`.
- Never add agent attribution (`Co-authored-by: Cursor`, `@cursoragent`, Made/Generated with Cursor).
- Changelog: behaviour agents rely on → `## [Unreleased]` in `CHANGELOG.md`.

Full detail: [docs/AGENTS.md](docs/AGENTS.md), [docs/agents/agent-contract.md](docs/agents/agent-contract.md).

## Key docs

| Topic | File |
| --- | --- |
| Full index + domain | [docs/AGENTS.md](docs/AGENTS.md) |
| Task contract | [docs/agents/agent-contract.md](docs/agents/agent-contract.md) |
| Risk tiers | [docs/agents/runtime-policy.md](docs/agents/runtime-policy.md) |
| AI skills map | [docs/ai-skills.md](docs/ai-skills.md) |
| Architecture | [docs/architecture.md](docs/architecture.md) |
| Claude Code MCP | [docs/claude-code.md](docs/claude-code.md) |
| Codex MCP | [docs/codex.md](docs/codex.md) |
| Examples | [examples/README.md](examples/README.md) |
| LLM entry | [llms.txt](llms.txt) |
