# Security policy

This repository is a **development-only** local environment, designed to run on
`127.0.0.1` and nowhere else. The threat model, the approval gate, and why the
Application Password works over plain HTTP are in
[docs/security.md](docs/security.md). Read it before reporting documented
behaviour.

## Supported versions

Only the current `main` is supported; fixes land there. Tagged releases older
than `main` are not.

## Reporting a vulnerability

**Do not open a public issue.** Use GitHub's private reporting on this
repository: **Security → Advisories → Report a vulnerability**. If that is
unavailable to you, email marcop135.github@gmail.com with `[security]` in the
subject.

Include what you found, the file or command it affects, how to reproduce it, and
what an attacker would gain. A proof of concept against a local clone is ideal.

Expect an acknowledgement within 7 days and an assessment within 14. Valid
findings are credited in the fix unless you prefer otherwise.

## Where to report

| Finding | Where |
|---------|-------|
| MCP Adapter: transport, sessions, permission callbacks | [WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter/security) |
| MS WordPress Abilities: an ability, the `rest-write` block list | here, since [ms-wp-abilities](https://github.com/miriamschwab/ms-wp-abilities) has no private reporting channel |
| WordPress core, including the Abilities API | [WordPress HackerOne](https://hackerone.com/wordpress) |
| This repository: scripts, image, Compose file, approval gate, credential handling, documentation | here |

## In scope

- A port binding, tunnel, override, or configuration here that reaches beyond
  loopback.
- A credential written to a tracked file, a log, a build layer or process
  output, or left world-readable under `.secrets/` or `.env`.
- A privilege the setup grants that it does not document.
- A default that weakens WordPress authentication or capability checks beyond
  `WP_ENVIRONMENT_TYPE = 'local'`, which is documented and deliberate.
- A write ability that `bin/ability-gate` lets through without asking in Claude
  Code or Cursor.

## Out of scope

- That the MCP endpoint can install plugins and write via REST as the
  administrator. That is the documented point of the tool.
- That a prompt-injected agent can misuse the credential it holds. The approval
  gate covers MCP writes in Claude Code and Cursor only; shell access and other
  clients are outside it, as documented.
- Anything that requires the user to have already exposed the site to a network.
