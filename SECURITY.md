# Security policy

This repository is a **development-only** local environment. It is designed to
run on `127.0.0.1` and nowhere else. The threat model, the reasons the
Application Password works over plain HTTP, and what the preview/confirm
convention does and does not guarantee are in
[docs/security.md](docs/security.md). Read that before reporting something that
is documented behaviour.

## Supported versions

| Version | Supported |
|---------|-----------|
| `main` | yes |
| any tagged release older than `main` | no |

There is one supported version: the current `main`. Fixes land there.

## Reporting a vulnerability

**Do not open a public issue.**

Use GitHub's private reporting on this repository: **Security → Advisories →
Report a vulnerability**. If that is unavailable to you, email
marcop135.github@gmail.com with `[security]` in the subject.

Include what you found, the file or command it affects, how to reproduce it, and
what an attacker would gain. A proof of concept against a local clone is ideal.

Expect an acknowledgement within 7 days and an assessment within 14. If the
finding is valid you will be credited in the fix unless you prefer otherwise.

## What belongs here, and what belongs upstream

This repository is wiring. Most of the attack surface it exposes is upstream
code, and a report there reaches the people who can fix it:

| Finding | Where |
|---------|-------|
| MCP Adapter: transport, sessions, permission callbacks | [WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter/security) |
| MS WP Abilities: an ability, the `rest-write` block list | [miriamschwab/ms-wp-abilities](https://github.com/miriamschwab/ms-wp-abilities/issues) |
| WordPress core, including the Abilities API | [WordPress HackerOne](https://hackerone.com/wordpress) |
| This repository: the scripts, the image, the Compose file, the credential handling, the documentation | here |

## In scope

- A port binding, tunnel, override, or configuration here that reaches beyond
  loopback.
- A credential written to a tracked file, a log, a build layer or process
  output, or left world-readable under `.secrets/` / `.env`.
- A privilege the setup grants that it does not document.
- A default that weakens WordPress authentication or capability checks beyond
  `WP_ENVIRONMENT_TYPE = 'local'`, which is documented and deliberate.

Threat model detail (secret modes, checksum pins, `--print` hygiene):
[docs/security.md](docs/security.md).

## Out of scope

- That the MCP endpoint can install plugins and write via REST as the
  administrator. That is the documented point of the tool.
- That a prompt-injected agent can misuse the credential it holds. Also
  documented: conversational confirmation is a convention, not a control.
- Anything that requires the user to have already exposed the site to a network.
