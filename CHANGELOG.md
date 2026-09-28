# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-09-28

First release of **wp-agent-harness** under this repository: a local, disposable
WordPress environment that coding agents drive through the official MCP Adapter.

### Added

- Docker Compose stack (WordPress 7.1 / PHP 8.3 / MariaDB 11.8) with loopback-only
  ports, idempotent `./bin/setup`, and `./bin/reset` for a clean rebuild.
- Pinned runtime installs of MCP Adapter and MS WordPress Abilities; WP-CLI plus
  `wp-cli/ability-command` in the image for a non-MCP diagnostic path.
- Application Password wiring and `./bin/connect` for Claude Code (local scope).
- Four test layers: repository integrity, smoke, MCP integration, and an optional
  headless Claude Code session.
- Curated WordPress agent skills under `.claude/skills/` and `.cursor/skills/`
  (GPL-2.0-or-later upstream copies), with stack precedence documented in
  `CLAUDE.md`.

[Unreleased]: https://github.com/marcop135/wp-agent-harness/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/marcop135/wp-agent-harness/releases/tag/v0.1.0
