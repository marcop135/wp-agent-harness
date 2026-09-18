# Examples

Prompts that work against this site, with the abilities each one exercises and
what you should see back. Run them from the repository directory with the MCP
server connected:

```bash
./bin/start
./bin/connect      # once, or again after ./bin/reset
cd . && claude
```

| Example | What it covers |
|---------|----------------|
| [inspect-site.md](inspect-site.md) | Version, theme, plugins, post types, content structure |
| [create-content.md](create-content.md) | A draft page with Gutenberg-compatible blocks |
| [modify-content.md](modify-content.md) | Restructuring an existing draft, with the change shown first |
| [theme.md](theme.md) | Reading Twenty Twenty-Five's templates and parts |
| [media.md](media.md) | Finding images with missing alt text, and fixing them |
| [plugins.md](plugins.md) | Installed plugins, their state, and available updates |
| [site-development.md](site-development.md) | Building a feature on the existing architecture |

These are documentation, not fixtures. Nothing here is committed to the
database, and running them leaves only what you ask for.

## How Claude reaches WordPress

Every one of these goes through the same three meta-tools:

```
mcp-adapter-discover-abilities   what can this site do?
mcp-adapter-get-ability-info     what does that ability expect?
mcp-adapter-execute-ability      do it
```

Expect Claude to make more than one tool call per prompt: a discovery or schema
lookup, then the real work. That is the MCP Adapter's design, not overhead you
can configure away. See
[docs/architecture.md](../docs/architecture.md#why-three-tools-and-not-thirty).

## The abilities behind them

```bash
./bin/wp ability list
./bin/wp ability list --namespace=miriamschwab --fields=name,label
```

Treat that output as authoritative. The examples name the abilities they use so
you can follow along, but the pinned MS WP Abilities release is what actually
defines the set.

## Reading and writing

Read-only prompts are safe to run at any time: `get-posts`, `get-pages`,
`get-media`, `get-plugins`, `get-themes`, `get-site-settings`, `get-menus`,
`get-available-updates`, `rest-get`, and all three `core/*` abilities.

Everything else changes the site. The write path in MS WP Abilities asks the
agent to state a proposed change and wait for your answer before applying it —
that is a working convention, not something the code enforces, so read what
Claude proposes. See [docs/security.md](../docs/security.md).

## A reproducible end-to-end demonstration

[create-content.md](create-content.md) ends with a create → read → modify →
verify → trash walkthrough on a page called **MCP Integration Test**. The
automated version of the same flow is:

```bash
./bin/test claude-code
```

which drives a real headless Claude Code session and checks every step against
the database with WP-CLI, then removes the page.
