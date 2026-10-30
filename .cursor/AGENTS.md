# Cursor agent instructions: Agent Harness for WordPress

Precedence shim for the **Cursor agent** (IDE agent mode). Full index and domain rules: **[docs/AGENTS.md](../docs/AGENTS.md)**.

**Maintenance:** When stack pins, commands, or skill triggers change, update this file together with [CLAUDE.md](../CLAUDE.md) and root [AGENTS.md](../AGENTS.md). See [docs/agents/agent-contract.md](../docs/agents/agent-contract.md) (Cross-tool parity).

## Precedence

If any instruction conflicts, use this order:

1. [`docs/AGENTS.md`](../docs/AGENTS.md)
2. [`docs/agents/agent-contract.md`](../docs/agents/agent-contract.md)
3. [`docs/agents/runtime-policy.md`](../docs/agents/runtime-policy.md)
4. Repo root [`AGENTS.md`](../AGENTS.md) (mirror / retrieval index)

## Mandatory reads for Cursor agent

- Runtime context, docs index, MCP/site rules: **`docs/AGENTS.md`**
- Task shape and verification: **`docs/agents/agent-contract.md`**
- Sandbox / autonomy and risk tiers: **`docs/agents/runtime-policy.md`**
- Skills: **`.claude/skills/`** (linked per skill from `.agents/skills/`)

## What this repo is

Local, disposable WordPress harness for coding agents. Docker Compose runs WordPress and MariaDB on loopback; agents talk to a real site over the official WordPress MCP Adapter. This repository does **not** ship an MCP server, abilities framework, or WordPress plugin of its own. The WordPress harness is localhost-only (not a production WordPress deploy); [`site/`](../site/) is the public marketing page. Connecting an agent to a separate live site is outside the harness: [remote-site.md](../docs/remote-site.md).

## Stack pin

```text
WordPress|7.1.3 (image wordpress:7.1.3-php8.3-apache) | PHP 8.3 | Apache 2.4
MariaDB|11.8.9
MCP Adapter|0.7.1 | MS WordPress Abilities|1.13.0
WP-CLI|2.12.0 + ability-command 1.0.2
MCP|discover / get-ability-info / execute-ability
Ports|127.0.0.1 only
```

Common mistakes:

- Inventing ability names or parameters instead of discover → schema → execute.
- Editing infra (`docker-compose.yml`, `bin/`, `.env`) for a content task.
- Publishing or destructive ops without an explicit ask.
- Committing credentials or binding ports beyond loopback.

## Commands (repo root)

| Task | Command |
| --- | --- |
| Provision | `./bin/setup` |
| MCP URL + auth export | `./bin/connect --print` |
| Health | `./bin/status` |
| WP-CLI / abilities | `./bin/wp …` |
| Demo content | `./bin/seed` |
| Write audit log | `./bin/audit` |
| Tests 0–3 | `./bin/test --skip-claude` |
| Reset volumes | `./bin/reset` (explicit ask only) |

`./bin/connect` registers Claude Code. For Cursor, use `./bin/connect --print`
for the HTTP URL and Authorization header, plus skills under `.claude/skills/`,
or `./bin/wp` for diagnostics.

## Git (summary)

- Branch from **`develop`** for day-to-day PRs; release cuts merge into **`main`**. No agent attribution on commits or PRs.
- Full contract: [docs/agents/agent-contract.md](../docs/agents/agent-contract.md).
