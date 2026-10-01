<p align="center">
  <img src="./docs/hero.png" alt="wp-agent-harness: agent, MCP Adapter, Abilities API, local WordPress" width="900" />
</p>

# wp-agent-harness

Production-shaped local WordPress for coding agents: pinned stack, localhost-only
ports, four automated test layers, one-command reset. Agents drive a real site
over the official [WordPress MCP Adapter](https://github.com/WordPress/mcp-adapter).

This repository is the glue (Compose, provisioning, auth, tests, docs, skills).
It does **not** ship an MCP server, abilities framework, or WordPress plugin of
its own. Upstream: [Abilities API](https://developer.wordpress.org/apis/abilities-api/),
[MCP Adapter](https://github.com/WordPress/mcp-adapter),
[MS WordPress Abilities](https://github.com/miriamschwab/ms-wp-abilities).

[![licence: MIT](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)
[![WordPress 7.1](https://img.shields.io/badge/WordPress-7.1-21759b.svg)](https://wordpress.org/)
[![MariaDB 11.8](https://img.shields.io/badge/MariaDB-11.8-C3363F.svg)](https://mariadb.org/)
[![Docker Compose v2](https://img.shields.io/badge/Docker_Compose-v2-2496ED.svg)](https://docs.docker.com/compose/)
[![MCP Adapter 0.6.1](https://img.shields.io/badge/MCP_Adapter-0.6.1-555.svg)](https://github.com/WordPress/mcp-adapter)
[![MS Abilities 1.12.0](https://img.shields.io/badge/MS_Abilities-1.12.0-555.svg)](https://github.com/miriamschwab/ms-wp-abilities)

**Development only.** Localhost only, no production data.
[Security](docs/security.md).

Agents: [docs/AGENTS.md](docs/AGENTS.md) · [llms.txt](llms.txt) · [docs/ai-skills.md](docs/ai-skills.md).

## Quick start

Needs Docker Compose v2, Git, and Bash.

```bash
git clone https://github.com/marcop135/wp-agent-harness.git
cd wp-agent-harness
./bin/setup
```

Connect an agent to the local WordPress site (pick one):

```bash
# Claude Code
./bin/connect && claude

# Codex (trust the project when prompted)
eval "$(./bin/connect --print | grep '^export ')"
codex

# Cursor: open this repo, then add an HTTP MCP server using
# the url and Authorization header printed by:
./bin/connect --print
```

Ask the agent to inspect the local site (version, theme, plugins).

Running setup again is safe; only `./bin/reset` wipes the site.
More detail: [Claude Code](docs/claude-code.md) · [Codex](docs/codex.md) ·
[Development](docs/development.md).

## What you get

| Piece | Role |
|-------|------|
| `./bin/*` | setup, status, reset, WP-CLI, tests; `connect` for Claude Code |
| MCP | three meta-tools: discover → schema → execute |
| Abilities | 26 `miriamschwab/*` + core abilities on a real local site |
| Tests | four layers: repo → infra → WordPress/abilities → MCP → Claude Code |
| Skills | curated WordPress agent skills under `.claude/skills/` and `.cursor/skills/` |

<p align="center">
  <img src="./docs/wp-admin-plugins.png" alt="wp-admin Plugins screen with MCP Adapter 0.6.1 and MS WordPress Abilities 1.12.0 active" width="760" />
</p>

Worked prompts: [examples/](examples/README.md). Stack diagram:
[docs/architecture.md](docs/architecture.md).

```bash
./bin/status
./bin/test --skip-claude    # layers 0–3, no model turns
./bin/wp ability list       # abilities without MCP
```

## Versions

WordPress 7.1 · PHP 8.3 · MariaDB 11.8 · MCP Adapter 0.6.1 · MS Abilities 1.12.0.

Full list: [docs/development.md](docs/development.md#versions).
How to update them: [Updating dependencies](docs/development.md#updating-dependencies).

## Docs

| Doc | Covers |
|-----|--------|
| [Development](docs/development.md) | Requirements, commands, versions, URLs, configuration |
| [Architecture](docs/architecture.md) | Stack, MCP meta-tools, project structure |
| [Claude Code](docs/claude-code.md) | Claude MCP registration, scopes, skills |
| [Codex](docs/codex.md) | Codex AGENTS.md + `.codex/config.toml` MCP |
| [Security](docs/security.md) | Threat model, bindings, credentials |
| [Troubleshooting](docs/troubleshooting.md) | Common failure modes |
| [Agents](docs/AGENTS.md) | Agent index and domain rules |
| [Examples](examples/README.md) | Worked prompts |

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md). Run `./bin/test --skip-claude` before a PR.

## Licence

MIT for the harness. Vendored WordPress agent skills are GPL-2.0-or-later.
Runtime installs keep their upstream licences; see
[Dependencies](docs/development.md#dependencies).
