![wp-agent-harness: local disposable WordPress for coding agents, over MCP. Agent, MCP Adapter, Abilities API, WordPress stack.](.github/brand/readme-light.png#gh-light-mode-only)
![wp-agent-harness: local disposable WordPress for coding agents, over MCP. Agent, MCP Adapter, Abilities API, WordPress stack.](.github/brand/readme-dark.png#gh-dark-mode-only)

# wp-agent-harness

A local WordPress site for coding agents (Claude Code, Codex, Cursor) to build
and edit through the official
[WordPress MCP Adapter](https://github.com/WordPress/mcp-adapter). It runs in
Docker on localhost with pinned versions, five test layers (0 to 4), and
`./bin/reset` to rebuild it in one command.

This repo only wires the pieces together. The MCP server, abilities and plugins
come from upstream: the
[Abilities API](https://developer.wordpress.org/apis/abilities-api/), the
[MCP Adapter](https://github.com/WordPress/mcp-adapter) and
[MS WordPress Abilities](https://github.com/miriamschwab/ms-wp-abilities).

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/marcop135/wp-agent-harness/test.yml?branch=develop&style=flat-square&label=CI)](https://github.com/marcop135/wp-agent-harness/actions/workflows/test.yml)
[![WordPress 7.1.2](https://img.shields.io/badge/WordPress-7.1.2-21759b.svg?style=flat-square)](https://wordpress.org/)
[![MariaDB 11.8.9](https://img.shields.io/badge/MariaDB-11.8.9-C3363F.svg?style=flat-square)](https://mariadb.org/)
[![Docker Compose v2](https://img.shields.io/badge/Docker_Compose-v2-2496ED.svg?style=flat-square)](https://docs.docker.com/compose/)
[![MCP Adapter 0.7.0](https://img.shields.io/badge/MCP_Adapter-0.7.0-555.svg?style=flat-square)](https://github.com/WordPress/mcp-adapter)
[![MS Abilities 1.12.0](https://img.shields.io/badge/MS_Abilities-1.12.0-555.svg?style=flat-square)](https://github.com/miriamschwab/ms-wp-abilities)

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
| Abilities | 26 `miriamschwab/*` + 3 `core/*` (= 29) on a real local site |
| Tests | five layers (0–4): repo → infra → WordPress/abilities → MCP → Claude Code |
| Skills | curated WordPress agent skills under `.claude/skills/` and `.cursor/skills/` |

Worked prompts: [examples/](examples/README.md). Stack diagram:
[docs/architecture.md](docs/architecture.md).

```bash
./bin/status
./bin/test --skip-claude    # layers 0–3, no model turns
./bin/wp ability list       # abilities without MCP
```

## Versions

WordPress 7.1.2 · PHP 8.3 · MariaDB 11.8.9 · MCP Adapter 0.7.0 · MS Abilities 1.12.0.

Full list: [docs/development.md](docs/development.md#versions).
How to update them: [Updating dependencies](docs/development.md#updating-dependencies).

## Docs

| Doc | Covers |
|-----|--------|
| [Development](docs/development.md) | Requirements, commands, versions, URLs, configuration |
| [Architecture](docs/architecture.md) | Stack, MCP meta-tools, project structure |
| [Claude Code](docs/claude-code.md) | Claude MCP registration, scopes, skills |
| [Codex](docs/codex.md) | Codex AGENTS.md + `.codex/config.toml` MCP |
| [Live site](docs/remote-site.md) | Pointing an agent at a remote site, outside the harness |
| [Security](docs/security.md) | Threat model, bindings, credentials |
| [Troubleshooting](docs/troubleshooting.md) | Common failure modes |
| [Agents](docs/AGENTS.md) | Agent index and domain rules |
| [Examples](examples/README.md) | Worked prompts |

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md). Run `./bin/test --skip-claude` before a PR.

## License

MIT for the harness ([LICENSE](LICENSE)). Vendored WordPress agent skills are
GPL-2.0-or-later. Runtime installs keep their upstream licences; see
[NOTICE](NOTICE) and [Dependencies](docs/development.md#dependencies).
