---
title: "Agent Harness for WordPress: Docker for AI agents"
canonical: https://wpagent.marcopontili.com/
description: Agent Harness for WordPress: local Docker WordPress for Claude Code, Cursor, and Codex. Loopback-only; one-command reset.
dateModified: 2026-10-17
---

# Agent Harness for WordPress

**Agent Harness for WordPress** is a local, disposable WordPress install for AI coding agents. It runs WordPress and MariaDB in Docker on loopback, exposes site abilities through the official [WordPress MCP Adapter](https://github.com/WordPress/mcp-adapter), and resets with one command. The repo wires the stack; it does not ship an MCP server or plugin of its own.

## What you get

A disposable harness, not a hosted WordPress. The MCP server and abilities come from upstream; this repo makes them reproducible.

Pinned: WordPress 7.1.2 · PHP 8.3 · MariaDB 11.8.9 · MCP Adapter 0.7.1 · MS Abilities 1.13.0.

| Piece | Role |
| --- | --- |
| Docker | WordPress and MariaDB published on `127.0.0.1` only |
| MCP Adapter | Three meta-tools: discover abilities, inspect a schema, execute |
| 29 abilities | 26 MS WordPress Abilities and 3 core ones, including a bridge to any REST route |
| Five test layers | From repo checks to a real headless Claude Code session, whose every step is checked against the database with WP-CLI |
| Agent skills | Curated WordPress skills for blocks, block themes, plugins, REST, the Abilities API, and WP-CLI |
| One-command reset | `./bin/reset` rebuilds a clean site; `./bin/setup` again never wipes content |

## How a request travels

1. **Agent:** Claude Code, Cursor, or Codex sends an HTTP MCP request, authenticated with a revocable Application Password.
2. **MCP Adapter:** listens on `127.0.0.1:8080` and answers with three meta-tools instead of thirty tools.
3. **Abilities API:** runs the ability with WordPress capability checks, the same rules wp-admin follows.
4. **WordPress:** a real install on Twenty Twenty-Five and MariaDB, with all data in disposable Docker volumes.

`./bin/wp ability list` skips MCP entirely: if an ability works there but not in your agent, the problem is in the MCP layer, not in WordPress.

## Quick start

Needs Docker Compose v2, Git, and Bash. About ten minutes from clone to first prompt.

```bash
git clone https://github.com/marcop135/wp-agent-harness.git
cd wp-agent-harness
./bin/setup
./bin/connect
```

- [README](https://github.com/marcop135/wp-agent-harness#readme)
- [Agent docs](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/AGENTS.md)
- [Architecture](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/architecture.md)
- [Security model](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/security.md)
- [Examples](https://github.com/marcop135/wp-agent-harness/tree/develop/examples)

## What to ask your agent

Worked examples from the repo, each with the abilities it uses and what you should see back.

- [Site inspection](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/inspect-site.md) (read-only): "Inspect the local WordPress site. Tell me the WordPress version, active theme, active plugins, site title, available post types, and current content structure."
- [Creating content](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/create-content.md) (markdown in, native blocks out): "Create a draft page called "About This Site". Use Gutenberg-compatible content with a heading, two paragraphs, and a list. Do not publish it."
- [Modifying content](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/modify-content.md) (the change shown first): "Find the draft page "About This Site" and improve its structure without changing its meaning. Show me the intended changes before applying them."
- [Media](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/media.md) (audit first, fix on request): "Inspect the media library and identify images with missing alt text."
- [Plugins and updates](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/plugins.md) (read-only): "Inspect the installed plugins and report their active/inactive state and available updates. Do not change anything."
- [Site development](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/site-development.md) (inspect, propose, build): "Build a Services section: a top-level "Services" page and three child pages. Keep everything as drafts and show me the structure before you start."

## Questions answered

### What is Agent Harness for WordPress?

Agent Harness for WordPress is a local Docker WordPress environment for coding agents. Agents talk to a real site through the official WordPress MCP Adapter and Abilities API. It is not a hosted WordPress product and does not ship its own MCP server or plugin.

### Which AI coding agents work with it?

Claude Code, Cursor, and Codex connect over HTTP MCP to the same endpoint. `./bin/connect` registers it with Claude Code; `./bin/connect --print` prints the URL and Authorization header for Cursor, and the variable the repo's `.codex/config.toml` reads for Codex.

### Is the WordPress site public?

No. WordPress is published on `127.0.0.1:8080` and MariaDB on `127.0.0.1:3307`, so no other machine can reach them. This website only describes the harness and has no MCP endpoint.

### Will the agent publish or delete things on its own?

The harness rules tell agents to work in drafts and to state a change before applying it, but that is a working convention, not a control. An MCP connection is admin access; MS WordPress Abilities hard-blocks only a few routes, such as permanent deletes and writes to users and settings. That is why the endpoint never leaves your machine.

### How do you reset the local site?

Run `./bin/reset`. It removes the containers and both Docker volumes, then runs `./bin/setup` again for a clean install; `--no-setup` stops after the wipe. `./bin/setup` on its own is idempotent and never wipes content.

### Can I point an agent at a live site?

The same MCP path works against any WordPress 6.9+ site running the MCP Adapter and MS WordPress Abilities, with an Application Password. [Connecting to a live site](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/remote-site.md) covers it, and it leaves the harness behind: no reset, no pinned stack, every call a real change.

### Does this repo ship an MCP server or plugin?

No. The MCP Adapter and MS WordPress Abilities come from upstream, pinned to tested releases. This repository provides Docker Compose, provisioning, tests, docs, and curated WordPress agent skills.

## License

**Development only.** The WordPress harness binds to localhost; this website only describes it.

Built and maintained by [Marco Pontili](https://marcopontili.com) · MIT · [marcop135/wp-agent-harness](https://github.com/marcop135/wp-agent-harness) · [Privacy](https://wpagent.marcopontili.com/privacy.html)
