---
title: "Agent Harness for WordPress: local WordPress for AI agents"
canonical: https://wpagent.marcopontili.com/
description: Local Docker WordPress for Claude Code, Cursor, and Codex, wired over MCP. Every change needs your approval and is logged; one command resets it.
dateModified: 2026-10-24
---

# Agent Harness for WordPress

**Agent Harness for WordPress** is a free, open-source WordPress site for AI coding agents like Claude Code, Codex, and Cursor, running in Docker on your computer. Agents work through the official WordPress [MCP Adapter](https://github.com/WordPress/mcp-adapter) and [Abilities API](https://developer.wordpress.org/apis/abilities-api/).

## What you get

A disposable harness, not a hosted WordPress. The MCP server and abilities come from upstream; this repo makes them reproducible.

| Piece | Role |
| --- | --- |
| Docker | WordPress and MariaDB on `127.0.0.1` only; `./bin/reset` rebuilds a clean site, `./bin/setup` again never wipes content |
| MCP Adapter | Three meta-tools: discover abilities, inspect a schema, execute |
| 29 abilities | 26 MS WordPress Abilities and 3 core ones, including a bridge to any REST route |
| Five test layers | From repo checks to a real headless Claude Code session, whose every step is checked against the database with WP-CLI |
| Agent skills | Curated WordPress skills for blocks, block themes, plugins, REST, the Abilities API, and WP-CLI |
| Approval gate | Your agent looks around freely but asks you before it changes anything, and every change is logged |

## Quick start

Needs Docker Compose v2, Git, Bash, curl, and jq. About ten minutes from clone to first prompt.

```bash
git clone https://github.com/marcop135/wp-agent-harness.git
cd wp-agent-harness
./bin/setup
./bin/connect
```

Cursor or Codex: [docs/codex.md](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/codex.md).

## What to ask your agent

Worked examples from the repo, each with the abilities it uses and what you should see back.

- [Site inspection](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/inspect-site.md) (read-only): "Inspect the local WordPress site. Tell me the WordPress version, active theme, active plugins, site title, available post types, and current content structure."
- [Creating content](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/create-content.md) (markdown in, native blocks out): "Create a draft page called "About This Site". Use Gutenberg-compatible content with a heading, two paragraphs, and a list. Do not publish it."
- [Modifying content](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/modify-content.md) (the change shown first): "Find the draft page "About This Site" and improve its structure without changing its meaning. Show me the intended changes before applying them."
- [Media](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/media.md) (audit first, fix on request): "Inspect the media library and identify images with missing alt text."
- [Plugins and updates](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/plugins.md) (read-only): "Inspect the installed plugins and report their active/inactive state and available updates. Do not change anything."
- [Site development](https://github.com/marcop135/wp-agent-harness/blob/develop/examples/site-development.md) (inspect, propose, build): "Build a Services section: a top-level "Services" page and three child pages. Keep everything as drafts and show me the structure before you start."

## How a request travels

In wp-admin you click Save. Here you type one sentence to your agent, and it makes four stops before anything changes on the site. You approve every change, and you can see where each request is.

1. **Your agent:** you describe the change in plain words. Claude Code, Cursor, or Codex turns it into an MCP request, signed with a revocable Application Password, so every change is made as the WordPress user it belongs to.
2. **Approval gate:** reads go straight through. Before any change, the agent stops and shows you exactly what it will do. Nothing happens until you say yes.
3. **MCP Adapter:** three meta-tools on `127.0.0.1:8080` find the right ability and run it through the Abilities API, with the same permission checks as wp-admin.
4. **WordPress:** a real install on Twenty Twenty-Five and MariaDB in disposable Docker volumes. The change is saved, logged, and reported back to your agent.

## Docs

- [README](https://github.com/marcop135/wp-agent-harness#readme)
- [Agent docs](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/AGENTS.md)
- [Architecture](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/architecture.md)
- [Security model](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/security.md)
- [Examples](https://github.com/marcop135/wp-agent-harness/tree/develop/examples)

## Questions answered

### What is Agent Harness for WordPress?

Agent Harness for WordPress is a free, open-source WordPress site for AI coding agents like Claude Code, Codex, and Cursor, running in Docker on your computer. Agents work through the official WordPress MCP Adapter and Abilities API.

### Which AI coding agents work with it?

Claude Code, Cursor, and Codex connect over HTTP MCP to the same endpoint. `./bin/connect` registers it with Claude Code; `./bin/connect --print` prints the URL and Authorization header for Cursor, and the variable the repo's `.codex/config.toml` reads for Codex.

### How is it different from wp-env or WordPress Playground?

[wp-env](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/) and [WordPress Playground](https://wordpress.org/playground/) give you a WordPress site; this harness also connects your coding agent to it. `./bin/setup` installs and authenticates the MCP Adapter and MS WordPress Abilities, Claude Code and Cursor ask before every write, and each change lands in an audit log.

### Is the WordPress site public?

No. WordPress is published on `127.0.0.1:8080` and MariaDB on `127.0.0.1:3307`, so no other machine can reach them. This website only describes the harness and has no MCP endpoint.

### Where does the site run, and how do I log in?

After `./bin/setup`, WordPress runs at `http://localhost:8080`. Log in to wp-admin as `admin` with the `WP_ADMIN_PASSWORD` that setup generates in `.env`.

### Will the agent publish or delete things on its own?

No. In Claude Code and Cursor, the agent asks you before every change, works in drafts, and every change it makes is logged. Codex uses its own approval settings. The site runs only on your computer, so no one else can reach it.

### How do you reset the local site?

Run `./bin/reset`. It removes the containers and both Docker volumes, then runs `./bin/setup` again for a clean install; `--no-setup` stops after the wipe. `./bin/setup` on its own is idempotent and never wipes content.

### Can I point an agent at a live site?

The same MCP path works against any WordPress 6.9+ site running the MCP Adapter and MS WordPress Abilities, with an Application Password. [Connecting to a live site](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/remote-site.md) covers it, and it leaves the harness behind: no reset, no pinned stack, every call a real change.

### Does this repo ship an MCP server or plugin?

No. The MCP Adapter and MS WordPress Abilities come from upstream, pinned to tested releases. This repository provides Docker Compose, provisioning, tests, docs, and curated WordPress agent skills.

## Try it with your agent

Free and open source. Setup takes about ten minutes, everything stays on your computer, and Claude Code and Cursor ask before they change anything. If an experiment goes wrong, `./bin/reset` gives you a fresh WordPress. [Get it on GitHub](https://github.com/marcop135/wp-agent-harness).

## License

Development only. The WordPress harness binds to localhost. This website only describes it.

Built and maintained by [Marco Pontili](https://marcopontili.com) · MIT · [marcop135/wp-agent-harness](https://github.com/marcop135/wp-agent-harness) · [Privacy](https://wpagent.marcopontili.com/privacy.html)
