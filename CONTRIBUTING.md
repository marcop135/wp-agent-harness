# Contributing

This repository is local infrastructure for driving WordPress from coding agents
over the MCP Adapter. It carries no MCP server, no abilities framework and no
WordPress plugin of its own, so a change here is almost always to a Bash script,
the Docker image, the tests or the documentation.

**A bug in an ability, in the MCP protocol handling, or in the adapter itself
belongs upstream:** [WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter/issues)
or MS WP Abilities (tracker linked in [NOTICE](NOTICE)).
`./bin/wp ability run <name> --user=admin` tells the two apart: if it fails
there, MCP is not involved.

## Setting up

```bash
git clone https://github.com/marcop135/wp-agent-harness.git
cd wp-agent-harness
./bin/setup          # idempotent; safe to re-run at any time
./bin/status         # every layer, in order
```

Requirements: [Development](docs/development.md#requirements). `shellcheck` is
not required locally, but CI runs it, so install it if you touch `bin/` or
`tests/`.

## Checklist

- [ ] Branch from `develop`; open the PR into `develop`. Release cuts merge
      `develop` into `main`.
- [ ] Run the checks:

  ```bash
  bash -n bin/* tests/*.sh
  shellcheck bin/* tests/*.sh
  docker compose config --quiet
  ./bin/test --skip-claude                       # layers 0-3, no model turns
  ./bin/reset --yes && ./bin/test --skip-claude  # a clean build still works
  ```

- [ ] `./bin/test claude-code` (layer 4, a real headless session; costs model
      turns) if you touched the connection path, the Application Password, or
      the abilities the test drives.
- [ ] Add a line under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md),
      following the rules at its top: Keep a Changelog, imperative voice, one
      line of at most 120 visible characters.
- [ ] One subject per PR. The description says what you ran; for a version pin,
      which upstream release and why; for docs, which file is now the single
      home for that topic.
- [ ] No agent attribution in commits, trailers, or the PR.

CI runs the same checks plus a full stack build, a reset and a rebuild on
Ubuntu, so a change that only works on your machine fails there.

## Conventions

- Every `bin/` script sources `bin/lib.sh` and nothing else.
- Anything that needs a container path goes through `wpx`, the only place
  `MSYS_NO_PATHCONV` is set.
- Never `curl -o /dev/null`; use `http_status` or `http_headers` from
  `bin/lib.sh`. Git Bash's native curl treats `/dev/null` as a filename.
- Provisioning steps check current state before changing it. `./bin/setup` stays
  idempotent and never destroys content: that is `./bin/reset`'s job alone.
- Tests name their content uniquely and delete it in an `EXIT` trap.
- Shell is Bash for `bin/`, `tests/`, and `docker/wordpress/bin/wp-provision`
  / `wp-app-password`; POSIX `sh` for `docker/wordpress/bin/wp`.
- PHP, JS and CSS follow the WordPress coding standards.
- Versions are pinned in `.env`, mirrored in `.env.example`; nothing follows a
  moving branch. Moving a pin:
  [docs/development.md](docs/development.md#updating-dependencies).
- Documentation grows by replacing, not appending. Each topic has one home:
  AGENTS (and `docs/agents/`), ai-skills, architecture, claude-code, codex,
  development, security, troubleshooting. Agent entry surfaces stay in parity:
  `docs/AGENTS.md`, root `AGENTS.md`, `CLAUDE.md`, `.cursor/AGENTS.md`, and
  `llms.txt`.

## Reporting

- **Bug or feature request:** open an issue with the matching template.
- **A question about using the site:** read
  [docs/troubleshooting.md](docs/troubleshooting.md) first, or open an
  [issue](https://github.com/marcop135/wp-agent-harness/issues/new/choose) and
  pick "Question".
- **A security problem:** do not open an issue. [SECURITY.md](SECURITY.md).

## Code of conduct

Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
