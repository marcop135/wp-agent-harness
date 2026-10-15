---
title: "Agent Harness for WordPress: Docker for AI agents"
canonical: https://wpagent.marcopontili.com/
description: Agent Harness for WordPress: local Docker WordPress for Claude Code, Cursor, and Codex over the official MCP Adapter. Loopback-only; one-command reset.
dateModified: 2026-10-15
---

# Agent Harness for WordPress

Give your coding agent a real WordPress site on localhost. Agent Harness for WordPress runs WordPress and MariaDB in Docker on your machine and connects Claude Code, Cursor, or Codex through the official MCP Adapter. When the agent breaks something, one command rebuilds it.

## What is Agent Harness for WordPress?

**Agent Harness for WordPress** is a local, disposable WordPress install for AI coding agents. It runs WordPress and MariaDB in Docker on loopback, exposes site abilities through the official [WordPress MCP Adapter](https://github.com/WordPress/mcp-adapter), and resets with one command. The repo wires the stack; it does not ship an MCP server or plugin of its own.

## Stack pin

| Piece | Version |
| --- | --- |
| WordPress | 7.1.2 |
| PHP / Apache | 8.3 / 2.4 |
| MariaDB | 11.8.9 |
| MCP Adapter | 0.7.0 |
| MS WordPress Abilities | 1.12.0 |
| Ports | 127.0.0.1 only |

## Architecture

Agent CLI, then MCP Adapter, then Abilities API, then WordPress in Docker. Nothing listens beyond 127.0.0.1.

1. **Agent CLI:** Claude Code, Cursor, or Codex, connected as an HTTP MCP client (`./bin/connect`).
2. **MCP Adapter:** the official WordPress endpoint, authenticated with an Application Password. Three meta-tools, not one tool per capability.
3. **Abilities API:** 26 `miriamschwab/*` abilities from MS WordPress Abilities plus 3 from WordPress core.
4. **WordPress in Docker:** WordPress on PHP 8.3 and Apache, MariaDB alongside, both bound to loopback.

`./bin/reset` destroys the Docker volumes and rebuilds a clean install. `./bin/setup` alone is idempotent and keeps your content.

## The loop

1. `mcp-adapter-discover-abilities`: list the abilities this site exposes.
2. `mcp-adapter-get-ability-info`: fetch one ability's input schema before calling it.
3. `mcp-adapter-execute-ability`: run the ability with parameters that match the schema.

`miriamschwab/rest-get` and `miriamschwab/rest-write` bridge to any registered REST route.

## What you get

| In this repository | From upstream |
| --- | --- |
| Docker Compose and `./bin/*`: setup, status, reset, WP-CLI, logs, tests | [WordPress MCP Adapter](https://github.com/WordPress/mcp-adapter): the MCP server |
| Five test layers: repository, infrastructure, WordPress and abilities, MCP, Claude Code | [Abilities API](https://developer.wordpress.org/apis/abilities-api/): how WordPress registers abilities |
| Curated WordPress agent skills for Claude Code and Cursor | [MS WordPress Abilities](https://github.com/miriamschwab/ms-wp-abilities): the abilities the agent calls |
| Docs and worked prompts | WordPress, MariaDB, WP-CLI at pinned versions |

## Quick start

Needs Docker Compose v2, Git, and Bash.

```bash
git clone https://github.com/marcop135/wp-agent-harness.git
cd wp-agent-harness
./bin/setup
```

Connect an agent:

```bash
# Claude Code
./bin/connect && claude

# Codex (trust the project when prompted)
eval "$(./bin/connect --print | grep '^export ')"
codex

# Cursor: add an HTTP MCP server with the url and Authorization header printed by
./bin/connect --print
```

Check every layer:

```bash
./bin/status
./bin/test --skip-claude
./bin/wp ability list
```

- [README](https://github.com/marcop135/wp-agent-harness#readme)
- [Agent docs](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/AGENTS.md)
- [Architecture doc](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/architecture.md)
- [Worked examples](https://github.com/marcop135/wp-agent-harness/tree/develop/examples)

## FAQ

### Which AI coding agents work with it?

Claude Code, Cursor, and Codex connect over HTTP MCP. Use `./bin/connect` for Claude Code, or `./bin/connect --print` for the MCP URL and Authorization header other clients need.

### Is the WordPress site public?

No. The harness binds WordPress and MariaDB to `127.0.0.1` only. This website is the project page and does not expose the MCP endpoint.

### How do you reset the local site?

Run `./bin/reset`. It destroys the Docker volumes and rebuilds a clean WordPress install. `./bin/setup` alone is idempotent and does not wipe content.

### Does this repo ship an MCP server or plugin?

No. The MCP Adapter and MS WordPress Abilities come from upstream. This repository provides Docker Compose, provisioning, tests, docs, and curated WordPress agent skills.

## License

MIT · [marcop135/wp-agent-harness](https://github.com/marcop135/wp-agent-harness) · [Privacy](https://wpagent.marcopontili.com/privacy.html)
