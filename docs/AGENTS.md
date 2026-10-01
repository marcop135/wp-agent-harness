# Agents: wp-agent-harness

Canonical narrative, documentation index, and working rules for this repository.

**Repo root [`AGENTS.md`](../AGENTS.md)** duplicates the retrieval index and condensed rules for tools that only read `AGENTS.md` at the repository root (see [Vercel: AGENTS.md vs skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)).

**Coding agents:** [Cursor agent](https://docs.cursor.com/agent) loads repo guidance via root [`AGENTS.md`](../AGENTS.md) and [`.cursor/AGENTS.md`](../.cursor/AGENTS.md) (precedence there). [Cursor CLI](https://cursor.com/docs/cli/using) reads root [`AGENTS.md`](../AGENTS.md) and [`CLAUDE.md`](../CLAUDE.md); it does not load `.cursor/AGENTS.md`. [Claude Code](https://code.claude.com/docs) reads [`CLAUDE.md`](../CLAUDE.md) at session start. Project skills live under [`.claude/skills/`](../.claude/skills/) and [`.cursor/skills/`](../.cursor/skills/) (same curated set). **Update this file** when changing shared narrative; then refresh the root mirror, `CLAUDE.md`, and `.cursor/AGENTS.md` pins if needed (see [agents/agent-contract.md](agents/agent-contract.md) Cross-tool parity).

Portable task contract: [agents/agent-contract.md](agents/agent-contract.md).

**IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning** for WordPress abilities, MCP tools, Docker commands, and this harness's `./bin/*` surface. Discover abilities and schemas at runtime; do not invent ability names or parameters from memory.

**What this repo is:** a local, disposable WordPress harness for coding agents. It does **not** ship an MCP server, an abilities framework, or a WordPress plugin of its own. Those live upstream. What lives here is Docker Compose, provisioning, Application Password auth for the MCP endpoint, four test layers, docs, examples, and a curated set of WordPress agent skills. Nothing here is public and nothing here is production.

## Stack pin

```text
WordPress|7.1.2 (image wordpress:7.1.2-php8.3-apache) | PHP 8.3 | Apache 2.4
MariaDB|11.8.9
MCP Adapter|0.6.1 (GitHub release ZIP)
MS WordPress Abilities|1.12.0 (GitHub release ZIP)
WP-CLI|2.12.0 + ability-command 1.0.2
MCP|meta-tools: discover / get-ability-info / execute-ability
Ports|127.0.0.1 only (WP + DB)
```

---

## [wp-agent-harness Docs Index]

Paths are repo-relative from project root unless noted.

|root:{README.md,CHANGELOG.md,AGENTS.md,CLAUDE.md,llms.txt,CONTRIBUTING.md,SECURITY.md,CODE_OF_CONDUCT.md,LICENSE,NOTICE,Makefile,docker-compose.yml,.env.example}
|docs:{AGENTS.md,ai-skills.md,architecture.md,claude-code.md,codex.md,development.md,security.md,troubleshooting.md}
|docs/agents:{README.md,agent-contract.md,runtime-policy.md}
|examples:{README.md,inspect-site.md,create-content.md,modify-content.md,media.md,theme.md,plugins.md,site-development.md}
|bin:{setup,start,stop,status,reset,connect,wp,logs,test,lib.sh}
|tests:{repo.sh,smoke.sh,integration.sh,claude-code.sh,lib.sh}
|docker/wordpress:{Dockerfile,wp-cli.yml,apache-wordpress.conf,ability-command-autoload.php,bin/wp,bin/wp-provision,bin/wp-app-password}
|.claude/skills:{wordpress-router,wp-abilities-api,wp-abilities-audit,wp-abilities-verify,wp-block-development,wp-block-themes,wp-patterns,wp-plugin-development,wp-project-triage,wp-rest-api,wp-wpcli-and-ops}
|.cursor:{AGENTS.md,skills/ (mirror of .claude/skills)}
|.codex:{config.toml}
|.github:{workflows/test.yml,dependabot.yml,CODEOWNERS,PULL_REQUEST_TEMPLATE.md,ISSUE_TEMPLATE/*}

---

## Commands

| Task | Command |
| --- | --- |
| First-time / idempotent provision | `./bin/setup` |
| Register MCP with Claude Code | `./bin/connect` |
| Container / WP / ability / MCP health | `./bin/status` |
| WP-CLI inside the container | `./bin/wp <args>` |
| List abilities without MCP | `./bin/wp ability list` |
| PHP debug log | `./bin/logs --debug` |
| Test layers 0–3 | `./bin/test --skip-claude` |
| Test layer 4 (costs model turns) | `./bin/test claude-code` |
| Destroy and rebuild volumes | `./bin/reset` (needs explicit ask) |

`./bin/wp ability list` and `./bin/wp ability run` are the independent diagnostic path: if an ability works there but not over MCP, the problem is in the MCP layer, not in WordPress.

---

## Condensed domain knowledge (read full files when editing)

**MCP loop:** The adapter's default server exposes three meta-tools, not one tool per capability: `mcp-adapter-discover-abilities`, `mcp-adapter-get-ability-info`, `mcp-adapter-execute-ability`. Discover, inspect the schema, execute. Call `get-ability-info` when unsure. Abilities come from MS WP Abilities (`miriamschwab/*`) and WordPress core (`core/*`). `miriamschwab/rest-get` and `miriamschwab/rest-write` bridge to any registered REST route.

**Site work:** Inspect before change. Prefer WordPress-native APIs and conventions. Write Gutenberg-compatible block markup; `create-post` accepts markdown and converts server-side. Default to drafts. Do not publish, delete, or bulk-change unless asked. Content edits: `patch-post-content` (surgical) or `preview-post-update` then `apply-post-update` (staged; state the change and wait for a real answer before applying). Destructive ops (trash, deactivate plugins, change site settings) need an explicit instruction first.

**Infrastructure vs site:** `docker-compose.yml`, `docker/`, `bin/`, and `.env` are the environment, not the site. Do not change them for a content or site-building task; say so first if a task needs an infra change. Volumes are disposable: `./bin/reset` destroys and rebuilds them. Never store non-reproducible data there.

**Skills:** Curated [WordPress/agent-skills](https://github.com/WordPress/agent-skills) under `.claude/skills/` and `.cursor/skills/` (blocks, themes, plugins, REST, Abilities API, WP-CLI, router/triage). They do not replace this stack. Site work still goes through the `wordpress` MCP abilities or `./bin/wp`. Do not switch to `@wordpress/env`, WordPress Playground, or Blueprints for the local site.

**Boundaries:** Never expose the MCP endpoint or the WordPress site beyond localhost. Never put credentials in a tracked file (`.env` and `.secrets/` stay ignored). Test content must be uniquely named and cleaned up. `./bin/reset` is the only thing allowed to destroy unrelated development content.

**Git:** Branch from `main`. Conventional subjects. PRs use `.github/PULL_REQUEST_TEMPLATE.md`. Never add agent attribution (`Co-authored-by: Cursor`, `@cursoragent`, Made/Generated with Cursor). Detail: [CONTRIBUTING.md](../CONTRIBUTING.md), [agents/agent-contract.md](agents/agent-contract.md).

**Upstream bugs:** Ability, MCP protocol, or adapter bugs belong upstream ([WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter/issues), [miriamschwab/ms-wp-abilities](https://github.com/miriamschwab/ms-wp-abilities/issues)), not here. Use `./bin/wp ability run <name> --user=admin` to tell the layers apart.
