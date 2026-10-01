# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- README screenshot of the wp-admin Plugins screen (`docs/wp-admin-plugins.png`).

## [0.2.0] - 2026-09-29

### Added

- Agent docs layer: `AGENTS.md`, `docs/AGENTS.md`, `.cursor/AGENTS.md`, `llms.txt`, `docs/ai-skills.md`, `docs/agents/`.
- Codex MCP: `.codex/config.toml`, `docs/codex.md`; `./bin/connect --print` works without Claude and exports `WORDPRESS_MCP_BASIC_AUTH`.
- README hero/OG assets and static shields (WordPress, MariaDB, Docker Compose, MCP Adapter, MS Abilities).

### Changed

- README trimmed; requirements, commands, URLs, versions, and test layers live in `docs/development.md`.
- Multi-agent quick start (Claude Code, Cursor, Codex).
- `CLAUDE.md` points at `docs/AGENTS.md`; architecture tree lists agent entry files and social assets.

## [0.1.0] - 2026-09-28

### Added

- Docker Compose stack (WordPress 7.1 / PHP 8.3 / MariaDB 11.8), loopback-only ports, `./bin/setup`, `./bin/reset`.
- Pinned MCP Adapter and MS WordPress Abilities; WP-CLI plus `wp-cli/ability-command` in the image.
- Application Password wiring and `./bin/connect` for Claude Code.
- Four test layers: repository, smoke, MCP, optional headless Claude Code.
- Curated WordPress agent skills under `.claude/skills/` and `.cursor/skills/`.

[Unreleased]: https://github.com/marcop135/wp-agent-harness/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/marcop135/wp-agent-harness/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/marcop135/wp-agent-harness/releases/tag/v0.1.0
