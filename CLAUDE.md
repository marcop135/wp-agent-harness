# Working in this repository

This is a local WordPress development environment. WordPress and MariaDB run in
Docker on this machine; you reach the site through the `wordpress` MCP server,
which is the local WordPress MCP Adapter endpoint. Nothing here is public and
nothing here is production.

## What the MCP server gives you

The MCP Adapter's default server exposes three meta-tools, not one tool per
capability:

- `mcp-adapter-discover-abilities` — list the abilities this site exposes
- `mcp-adapter-get-ability-info` — fetch one ability's input schema
- `mcp-adapter-execute-ability` — run an ability with parameters

So the loop is: discover, inspect the schema, execute. Do not assume ability
names or parameters from memory — call `get-ability-info` when you are unsure.
The abilities themselves come from the MS WP Abilities plugin (`miriamschwab/*`)
and WordPress core (`core/*`).

`miriamschwab/rest-get` and `miriamschwab/rest-write` bridge to any registered
REST route, so reach for them before concluding something is not possible.

## How to work on this site

- Inspect before you change. Read the current state of a post, setting or
  plugin before modifying it, and say what you found.
- Prefer WordPress-native APIs and established WordPress conventions over
  bespoke solutions. If core or the active theme already does something, use it.
- Write block markup. Content should be Gutenberg-compatible; `create-post`
  accepts markdown and converts it to native blocks server-side, which is
  usually the cleanest route.
- Follow WordPress coding standards in any PHP, JS or CSS you write.
- Default to drafts. Do not publish, delete or bulk-change anything unless the
  task asks for it.
- For content edits, `patch-post-content` is the surgical option;
  `preview-post-update` then `apply-post-update` is the staged one. State the
  proposed change in plain language and wait for a real answer before applying
  it — that two-step model is a working convention, not something the code
  enforces.
- Destructive operations (trashing, deactivating plugins, changing site
  settings) need an explicit instruction first.

## Infrastructure

`docker-compose.yml`, `docker/`, `bin/` and `.env` are the environment, not the
site. Do not change them for a content or site-building task. If a task really
needs an infrastructure change, say so before making it.

The database and the WordPress install live in Docker volumes and are
disposable: `./bin/reset` destroys and rebuilds them. Do not treat anything in
them as durable, and do not store anything there that is not reproducible.

## Commands

    ./bin/status              container, WordPress, ability and MCP health
    ./bin/wp <wp-cli args>    WP-CLI inside the container
    ./bin/wp ability list     the abilities this site registers, without MCP
    ./bin/logs --debug        WordPress's own PHP debug log
    ./bin/test --skip-claude  layers 1-3 of the test suite

`./bin/wp ability list` and `./bin/wp ability run` are the independent
diagnostic path: if an ability works there but not over MCP, the problem is in
the MCP layer, not in WordPress.

## Skills

A curated subset of [WordPress/agent-skills](https://github.com/WordPress/agent-skills)
lives under `.claude/skills/` and `.cursor/skills/` (blocks, themes, plugins,
REST, Abilities API, WP-CLI, router/triage). Use them for WordPress coding
patterns.

They do not replace this stack. Site work still goes through the `wordpress` MCP
abilities or `./bin/wp`. Do not switch to `@wordpress/env`, WordPress Playground,
or Blueprints for the local site; this repository's Docker Compose setup is the
environment. Content and admin rules above still apply (drafts by default,
inspect before change, no destructive ops without an explicit ask).

## Boundaries

- Never expose the MCP endpoint or the WordPress site beyond localhost.
- Never put credentials in a tracked file. `.env` and `.secrets/` are ignored
  and must stay that way; the Application Password lives in Claude Code's own
  config, outside this repository.
- Test content must be uniquely named and cleaned up. `./bin/reset` is the only
  thing allowed to destroy unrelated development content.
