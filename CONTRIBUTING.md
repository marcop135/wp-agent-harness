# Contributing

This repository is local infrastructure for driving WordPress from coding agents
over the MCP Adapter. It carries no MCP server, no abilities framework and no
WordPress plugin of its own, so a change here is almost always to a Bash script,
the Docker image, the tests or the documentation.

**A bug in an ability, in the MCP protocol handling, or in the adapter itself
belongs upstream**, not here:

- [WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter/issues)
- [miriamschwab/ms-wp-abilities](https://github.com/miriamschwab/ms-wp-abilities/issues)

`./bin/wp ability run <name> --user=admin` is how you tell the two apart: if it
fails there, MCP is not involved.

## Setting up

```bash
git clone https://github.com/marcop135/wp-agent-harness.git
cd wp-agent-harness
./bin/setup          # idempotent; safe to re-run at any time
./bin/status         # every layer, in order
```

Requirements are in [Development](docs/development.md#requirements). `shellcheck` is not
required locally, but CI runs it, so install it if you touch `bin/` or `tests/`.

## The loop

```bash
./bin/start
# change something
./bin/test --skip-claude                       # layers 0-3, no model turns
./bin/reset --yes && ./bin/test --skip-claude  # prove a clean build still works
```

`./bin/test claude-code` runs layer 4, a real headless Claude Code session. It
costs model turns, so run it when you have touched the connection path, the
Application Password, or the abilities the test drives.

## Conventions

- Every `bin/` script sources `bin/lib.sh` and nothing else.
- Anything that needs a container path goes through `wpx`, the only place
  `MSYS_NO_PATHCONV` is set.
- Never `curl -o /dev/null`; use `http_status` or `http_headers` from
  `bin/lib.sh`. Git Bash's native curl treats `/dev/null` as a filename.
- Provisioning steps check current state before changing it. `./bin/setup` must
  stay idempotent, and must never destroy content: that is `./bin/reset`'s job
  alone.
- Tests name their content uniquely and delete it in an `EXIT` trap.
- Shell is Bash for `bin/` and `tests/`, POSIX `sh` for
  `docker/wordpress/bin/`, which CI shellchecks with `--shell=sh`.
- PHP, JS and CSS follow the WordPress coding standards.
- Versions are pinned in `.env`, mirrored in `.env.example`. Nothing follows a
  moving branch. Moving a pin is
  [docs/development.md](docs/development.md#updating-dependencies).
- Documentation grows by replacing, not appending. Each topic has one home:
  AGENTS (and `docs/agents/`), ai-skills, architecture, claude-code, development,
  security, troubleshooting. Agent entry surfaces stay in parity: `docs/AGENTS.md`,
  root `AGENTS.md`, `CLAUDE.md`, `.cursor/AGENTS.md`, and `llms.txt`.

## Before opening a pull request

```bash
bash -n bin/* tests/*.sh
shellcheck bin/* tests/*.sh
docker compose config --quiet
./bin/test --skip-claude
```

CI runs the same checks plus a full stack build, a reset and a rebuild on
Ubuntu, so a change that only works on your machine fails there.

Branch from `main`, keep the pull request to one subject, and say in the
description what you ran. If you changed a version pin, say which upstream
release and why. If you changed documentation, say which file is now the single
home for that topic.

## Reporting

- **Bug or feature request:** open an issue with the matching template.
- **A question about using the site:** that is not a bug; open a
  [discussion-style issue](https://github.com/marcop135/wp-agent-harness/issues/new/choose)
  and pick "Question", or read [docs/troubleshooting.md](docs/troubleshooting.md)
  first, which covers most of them.
- **A security problem:** do not open an issue. [SECURITY.md](SECURITY.md).

## Code of conduct

Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
