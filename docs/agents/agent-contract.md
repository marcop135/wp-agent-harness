# Agent contract: wp-agent-harness

Portable rules for AI agents (Cursor agent, Claude Code, and similar). Canonical narrative: [`docs/AGENTS.md`](../AGENTS.md).

## Product context

- **This repo:** a local, disposable WordPress harness for coding agents. Docker Compose runs WordPress and MariaDB on loopback; agents reach the site through the WordPress MCP Adapter (`wordpress` MCP server) or `./bin/wp`.
- **Not shipped here:** MCP server implementation, Abilities API framework, or a first-party WordPress plugin. Those live upstream ([WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter), [miriamschwab/ms-wp-abilities](https://github.com/miriamschwab/ms-wp-abilities), WordPress core).
- **Boundary:** nothing is public; nothing is production. Ports bind to `127.0.0.1`. Credentials stay out of tracked files.

## Task template (non-trivial work)

1. **Goal:** one sentence.
2. **Risk tier:** Low | Medium | High; see [runtime-policy.md](runtime-policy.md).
3. **Scope:** paths and files; explicit non-goals.
4. **Constraints:** rules in [`docs/AGENTS.md`](../AGENTS.md); no drive-by refactors; no infra edits for a content task.
5. **Done when:** e.g. `./bin/test --skip-claude` for harness changes; ability discovery + execute for site tasks; changelog updated when behaviour agents rely on changes.
6. **Changelog:** Keep a Changelog under `## [Unreleased]` in `CHANGELOG.md`.

## Git and PRs

- Integration work lands on **`develop`**; cut releases to **`main`**. Branch
  feature work from `develop` (or from `main` only when cutting a release PR).
  Keep the pull request to one subject.
- Use `.github/PULL_REQUEST_TEMPLATE.md`.
- **No agent attribution:** never add `Co-authored-by: Cursor`, `@cursoragent`, Made/Generated with Cursor, Claude trailers, or any copy that puts an agent in GitHub Contributors.
- Upstream ability/adapter bugs: file upstream, not here. Prove with `./bin/wp ability run` when split matters.

## Verification

- **Harness (`bin/`, `docker/`, `tests/`, docs pins):** `./bin/test --skip-claude` (layers 0–3). Layer 4 (`./bin/test claude-code`) only when the connection path, Application Password, or abilities the test drives changed.
- **Site / content via MCP:** discover → `get-ability-info` → execute. Prefer `./bin/wp ability …` to isolate MCP from WordPress.
- **Clean rebuild:** when provisioning or image pins change, `./bin/reset --yes && ./bin/test --skip-claude`.
- **Shell:** CI runs `shellcheck` on `bin/*` and `tests/*.sh`; run it locally when those paths change.

## Documentation and retrieval

- Prefer [`docs/AGENTS.md`](../AGENTS.md) and linked files over model memory for abilities, MCP, Docker, and `./bin/*`.
- Worked prompts: [`examples/`](../../examples/). Architecture: [`docs/architecture.md`](../architecture.md).

## Cross-tool layout

- **Canonical narrative:** [`docs/AGENTS.md`](../AGENTS.md).
- **Root mirror:** [`AGENTS.md`](../../AGENTS.md).
- **Claude Code:** [`CLAUDE.md`](../../CLAUDE.md).
- **Cursor agent:** [`.cursor/AGENTS.md`](../../.cursor/AGENTS.md).

### Cross-tool parity

When changing team-wide agent behavior, keep these surfaces aligned in the same PR:

- **Commands, MCP/site rules, skill triggers:** [`docs/AGENTS.md`](../AGENTS.md), root [`AGENTS.md`](../../AGENTS.md), [`CLAUDE.md`](../../CLAUDE.md), [`.cursor/AGENTS.md`](../../.cursor/AGENTS.md).
- **Skills:** keep `.claude/skills/` and `.cursor/skills/` in sync (same curated set).

Optional sanity check before merge: compare substantive sections of `docs/AGENTS.md`, root `AGENTS.md`, `CLAUDE.md`, and `.cursor/AGENTS.md` (excluding the Cursor precedence block).

Tool loading matrix: [README.md](README.md).

## Cursor CLI

- **Context:** loads root `AGENTS.md` + `CLAUDE.md` + project skills.
- **Headless:** `agent -p --force` from the repository root with parent guidance loaded in context.
