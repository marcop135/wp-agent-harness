# Changelog

- **Format:** Based on [Keep a Changelog](https://keepachangelog.com).
- **Voice:** Use the imperative, like a commit message. Write add, fix, increase, force, not added, fixed, increased, forced.
- **Length:** Keep each bullet on one line, max 120 characters (link URLs do not count toward the cap, only the visible text does).
- **Links:** Add inline markdown links for related PRs, docs, and external references when they help the reader.

## [Unreleased]

## [0.4.1] - 2026-10-02

### Changed

- MCP Adapter pin 0.6.1 → 0.7.0.

## [0.4.0] - 2026-10-01

### Added

- [`NOTICE`](https://github.com/marcop135/wp-agent-harness/blob/develop/NOTICE) for third-party and runtime licence notes (vendored skills, setup installs).
- CI status badge on the README.

### Changed

- [`LICENSE`](https://github.com/marcop135/wp-agent-harness/blob/develop/LICENSE) is pure MIT so GitHub detects SPDX MIT; third-party notes live in [`NOTICE`](https://github.com/marcop135/wp-agent-harness/blob/develop/NOTICE).
- README License badge/heading; License section links [`NOTICE`](https://github.com/marcop135/wp-agent-harness/blob/develop/NOTICE) and Dependencies.
- [`CONTRIBUTING.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/CONTRIBUTING.md) requirements link points at [`docs/development.md#requirements`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/development.md#requirements).

### Removed

- `docs/wp-admin-plugins.png` README screenshot (redundant with version pins and badges).

## [0.3.0] - 2026-10-01

### Added

- README screenshot of the wp-admin Plugins screen (`docs/wp-admin-plugins.png`).
- [`.github/brand/`](https://github.com/marcop135/wp-agent-harness/blob/develop/.github/brand/): README, OG and GitHub social images as SVG source + PNG in Catamaran, Cabin and Roboto Mono, rendered by `render.mjs` (`--check` for staleness).

### Changed

- WordPress pinned to 7.1.2 (`wordpress:7.1.2-php8.3-apache`).
- [`docs/development.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/development.md): a `WORDPRESS_IMAGE` bump needs `./bin/wp core update`, since core lives in the volume.

### Removed

- `docs/hero.png`, `docs/og.png`, `docs/og.svg`, replaced by [`.github/brand/readme.png`](https://github.com/marcop135/wp-agent-harness/blob/develop/.github/brand/readme.png), `og.png` and `social.png`.

## [0.2.0] - 2026-09-29

### Added

- Agent docs layer: [`AGENTS.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/AGENTS.md), [`docs/AGENTS.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/AGENTS.md), [`.cursor/AGENTS.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/.cursor/AGENTS.md), [`llms.txt`](https://github.com/marcop135/wp-agent-harness/blob/develop/llms.txt), [`docs/ai-skills.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/ai-skills.md), [`docs/agents/`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/agents/).
- Codex MCP: [`.codex/config.toml`](https://github.com/marcop135/wp-agent-harness/blob/develop/.codex/config.toml), [`docs/codex.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/codex.md); `./bin/connect --print` works without Claude and exports `WORDPRESS_MCP_BASIC_AUTH`.
- README hero/OG assets and static shields (WordPress, MariaDB, Docker Compose, MCP Adapter, MS Abilities).

### Changed

- README trimmed; requirements, commands, URLs, versions, and test layers live in [`docs/development.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/development.md).
- Multi-agent quick start (Claude Code, Cursor, Codex).
- [`CLAUDE.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/CLAUDE.md) points at [`docs/AGENTS.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/AGENTS.md); architecture tree lists agent entry files and social assets.

## [0.1.0] - 2026-09-28

### Added

- Docker Compose stack (WordPress 7.1 / PHP 8.3 / MariaDB 11.8), loopback-only ports, [`./bin/setup`](https://github.com/marcop135/wp-agent-harness/blob/develop/bin/setup), [`./bin/reset`](https://github.com/marcop135/wp-agent-harness/blob/develop/bin/reset).
- Pinned MCP Adapter and MS WordPress Abilities; WP-CLI plus `wp-cli/ability-command` in the image.
- Application Password wiring and [`./bin/connect`](https://github.com/marcop135/wp-agent-harness/blob/develop/bin/connect) for Claude Code.
- Four test layers: repository, smoke, MCP, optional headless Claude Code.
- Curated WordPress agent skills under [`.claude/skills/`](https://github.com/marcop135/wp-agent-harness/blob/develop/.claude/skills/) and [`.cursor/skills/`](https://github.com/marcop135/wp-agent-harness/blob/develop/.cursor/skills/).
