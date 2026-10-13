---
title: "wp-agent-harness: local WordPress for AI agents"
canonical: https://wp-agent-harness.netlify.app/
description: Run disposable WordPress in Docker for Claude Code, Cursor, and Codex via the official MCP Adapter. Loopback-only, pinned versions, one-command reset.
dateModified: 2026-10-13
---

# wp-agent-harness

**wp-agent-harness** is a local, disposable WordPress install for AI coding agents. It runs WordPress and MariaDB in Docker on loopback, exposes site abilities through the official [WordPress MCP Adapter](https://github.com/WordPress/mcp-adapter), and resets with one command. The repo wires the stack; it does not ship an MCP server or plugin of its own.

## What you get

| Piece | Role |
| --- | --- |
| Docker | WordPress and MariaDB on loopback only, pinned images, one-command provision |
| MCP Adapter | Three meta-tools: discover abilities, inspect schemas, execute |
| Abilities | MS WordPress Abilities plus core site info on a real local install |

## Quick start

Needs Docker Compose v2, Git, and Bash.

```bash
git clone https://github.com/marcop135/wp-agent-harness.git
cd wp-agent-harness
./bin/setup
./bin/connect
```

- [README](https://github.com/marcop135/wp-agent-harness#readme)
- [Agent docs](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/AGENTS.md)
- [Architecture](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/architecture.md)
- [Examples](https://github.com/marcop135/wp-agent-harness/tree/develop/examples)

## FAQ

### Which AI coding agents work with it?

Claude Code, Cursor, and Codex connect over HTTP MCP. Use `./bin/connect` for Claude Code, or `./bin/connect --print` for the MCP URL and Authorization header other clients need.

### Is the WordPress site public?

No. The harness binds WordPress and MariaDB to `127.0.0.1` only. This page is marketing only and does not expose the MCP endpoint.

### How do you reset the local site?

Run `./bin/reset`. It destroys the Docker volumes and rebuilds a clean WordPress install. `./bin/setup` alone is idempotent and does not wipe content.

### Does this repo ship an MCP server or plugin?

No. The MCP Adapter and MS WordPress Abilities come from upstream. This repository provides Docker Compose, provisioning, tests, docs, and curated WordPress agent skills.

## License

MIT · [marcop135/wp-agent-harness](https://github.com/marcop135/wp-agent-harness)
