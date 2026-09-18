# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Repository

- Community health files: `CONTRIBUTING.md`, `SECURITY.md` (private reporting,
  and what belongs upstream instead), `CODE_OF_CONDUCT.md`.
- `.github/`: YAML issue forms for bug, feature and question, blank issues off,
  a pull request template that asks which test layers were run, `CODEOWNERS`,
  and Dependabot for the workflow's own actions.
- `.gitattributes`: `eol=lf` for everything, so a Windows checkout cannot break
  a container shebang; `export-ignore` for scaffolding.
- `tests/repo.sh` covers all of the above.

### Documentation

Streamlined to one home per topic. The README lost the duplicated dependency
procedure, debugging hierarchy and reset walkthrough, which now live in
`docs/development.md`, `docs/troubleshooting.md` and the commands table; the
three-meta-tool explanation is stated once and linked from the other three
places. Contributor conventions moved out of `docs/development.md` into
`CONTRIBUTING.md`. README is a fifth shorter (2361 → 1944 words) and carries
build, licence and WordPress badges.

## [1.0.0] — 2026-09-18

First working version. Claude Code drives a local WordPress site through the
official MCP Adapter, verified end to end.

### Environment

- Docker Compose stack: WordPress 7.1 on PHP 8.3 and Apache 2.4, MariaDB 11.8.9.
  Both ports bound to `127.0.0.1`, both data sets in named volumes.
- WordPress image adds WP-CLI 2.12.0 (SHA-512 verified) and
  `wp-cli/ability-command` 1.0.2, so `wp ability` works as a diagnostic path
  that does not go through MCP.
- MCP Adapter 0.6.1 and MS WordPress Abilities 1.12.0, installed from pinned
  upstream GitHub release ZIPs. Twenty Twenty-Five activated. Akismet and Hello
  Dolly removed.
- Every version is a variable in `.env`; nothing follows a moving branch.

### Commands

`./bin/setup`, `start`, `stop`, `reset`, `status`, `logs`, `test`, `connect`,
plus `./bin/wp` for WP-CLI in the container, and a Makefile over the same set.
Setup is idempotent; `reset` is the only thing that destroys state.

### Authentication

WordPress Application Password over HTTP Basic, issued and rotated by setup,
stored in git-ignored `.secrets/` and in Claude Code's own configuration.
`WP_ENVIRONMENT_TYPE = 'local'` is the single concession that lets WordPress
accept it over plain HTTP; no authentication is disabled anywhere.

### Tests

- `tests/repo.sh` — secrets, `.gitignore`, shell syntax, version drift, loopback bindings
- `tests/smoke.sh` — layer 1 infrastructure, layer 2 WordPress and the Abilities API
- `tests/integration.sh` — layer 3, the full MCP Streamable HTTP flow and a create/modify/trash cycle
- `tests/claude-code.sh` — layer 4, a real headless `claude -p` session checked against the database

### CI

GitHub Actions runs shell linting, repository integrity and a full stack build
with layers 1-3 on Ubuntu. No credentials are involved.

### Documentation

README, `docs/architecture.md`, `docs/claude-code.md`, `docs/development.md`,
`docs/security.md`, `docs/troubleshooting.md`, seven worked examples, and a
`CLAUDE.md` that gives Claude Code its working context.

[1.0.0]: https://github.com/marcop135/wordpress-claude-mcp/releases/tag/v1.0.0
