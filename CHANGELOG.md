# Changelog

- **Format:** Based on [Keep a Changelog](https://keepachangelog.com).
- **Voice:** Use the imperative, like a commit message. Write add, fix, increase, force, not added, fixed, increased, forced.
- **Length:** Keep each bullet on one line, max 120 characters (link URLs do not count toward the cap, only the visible text does).
- **Links:** Add inline markdown links for related PRs, docs, and external references when they help the reader.

## [Unreleased]

## [0.11.0] - 2026-10-24

### Added

- Add [abilities reference](docs/abilities.md).
- Add website FAQ on wp-env, Playground, and login.

### Changed

- Bump WordPress to 7.1.3.
- Skip Netlify builds; the host only redirects.
- Report MS WordPress Abilities vulnerabilities here: upstream has no private channel ([SECURITY.md](SECURITY.md)).

## [0.10.2] - 2026-10-24

### Changed

- Refer to MS WP Abilities by name in docs, examples, and issue templates, with its upstream links in `NOTICE`.

### Fixed

- Name the admin login a write runs as in the approval prompt (`WP_ADMIN_USER`) and drop the plugin namespace.

## [0.10.1] - 2026-10-23

### Fixed

- Name the connected WordPress user in the approval prompt, so the plugin namespace reads as a namespace, not the author.

## [0.10.0] - 2026-10-23

### Changed

- Animate the website title, Quick start, and request flow.
- Add a closing "Run it on your machine" section to the website.
- Show the animated request flow in the README, linked to the website.

## [0.9.0] - 2026-10-22

### Added

- Add a write approval gate: Claude Code and Cursor ask before every write ability ([security](docs/security.md#the-approval-gate)).
- Add `./bin/audit` to list the writes agents made, and `./bin/seed` for demo content (`--remove` deletes it).
- Test the gate in layer 0, and against the plugin's policy table and audit log in layer 3.

### Changed

- Rework the README and website around the request flow: example prompts, diagram, icon tiles, redrawn images.
- Streamline the docs and examples into tables that follow the request path, and document the gate for live sites.
- Run test layer 4 without project settings, since a headless turn cannot answer the approval gate.

## [0.8.1] - 2026-10-18

### Changed

- Update MS WP Abilities to 1.13.0, letting `create-post` credit a named author.

## [0.8.0] - 2026-10-17

### Added

- Add a copy button to the website's quick-start snippet and to each example prompt.
- Add a "How a request travels" section tracing agent, MCP Adapter, Abilities API, and WordPress.
- Add six copy-ready prompts from [examples/](https://github.com/marcop135/wp-agent-harness/tree/develop/examples) to the website.
- Add website FAQ answers on agent writes and on pointing an agent at a live site.

### Changed

- Animate website FAQ answers as they open and close, honouring reduced motion.
- Show a "Development only" note and the maintainer above the website footer links on every page.
- Expand the website's feature grid to six items and show the pinned versions in the hero.

## [0.7.3] - 2026-10-16

### Fixed

- Report self-hosted Matomo page views to this site's own property instead of the shared one.

## [0.7.2] - 2026-10-16

### Security

- Update [MCP Adapter to 0.7.1](https://github.com/WordPress/mcp-adapter/releases/tag/v0.7.1) to limit stored session data.

## [0.7.1] - 2026-10-16

### Changed

- Redirect every Netlify path to [wpagent.marcopontili.com](https://wpagent.marcopontili.com) with a forced 301.

## [0.7.0] - 2026-10-16

### Added

- Add `site/.htaccess` (security headers, CSP, caching, compression) and a `deploy.yml` that mirrors only `site/`.
- Add cookieless self-hosted Matomo with a matching CSP and a rewritten privacy notice.

### Changed

- Move the website to [wpagent.marcopontili.com](https://wpagent.marcopontili.com) on Netsons; Netlify stays for previews.
- Redesign the website: editorial layout, architecture diagram, copyable quick-start blocks, light and dark.

## [0.6.0] - 2026-10-13

### Changed

- Rename the display name to Agent Harness for WordPress.

### Fixed

- Marketing site: stop hero grid drift.

## [0.5.1] - 2026-10-13

### Fixed

- Close Website Spec gaps on the Netlify marketing site (404/privacy, headers, contrast, a11y, caching).

## [0.5.0] - 2026-10-13

### Added

- Add a public marketing site in [`site/`](site/) (Netlify, Prism, favicons, JSON-LD/FAQ/sitemap/`llms.txt`).

## [0.4.5] - 2026-10-09

### Changed

- Redraw `.github/brand/og.png` in the light README header design.
- Re-render the README and social PNGs with the pinned render toolchain.

## [0.4.4] - 2026-10-08

### Added

- Add [`docs/remote-site.md`](docs/remote-site.md): connect an agent to a live WordPress site, outside the harness.

### Changed

- Restructure `docs/` for scanning: symptom index in troubleshooting, tables over prose, shorter sentences.
- Scope the localhost-only boundary to the harness in `CLAUDE.md`, `AGENTS.md` mirrors, and `llms.txt`.

### Fixed

- Correct docs: five test layers, branch from `develop`, public repo, Apache mod_php (not PHP-FPM).
- Correct the layer 0 description: it compares `.env.example` with `docs/development.md`, not the README.

## [0.4.3] - 2026-10-08

### Changed

- Make `./bin/reset` remove all of `.secrets/` and the Claude Code MCP registration.
- Warn on `./bin/connect --print` that stdout carries a live Basic auth header.

### Fixed

- Correct [`CLAUDE.md`](CLAUDE.md): `--skip-claude` runs layers 0–3, not 1–3.

### Security

- Verify SHA-256 checksums for the MCP Adapter, MS WP Abilities, and `ability-command` downloads.
- Refuse non-loopback port bindings and `network_mode: host` in `./bin/setup` and `./bin/status`.
- Enforce mode `600` on `.env` and the Application Password, and `700` on `.secrets/`, where modes apply.

## [0.4.2] - 2026-10-05

### Changed

- Standardize the changelog on Format/Voice/Length/Links, inline links, and KaC section order.

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
