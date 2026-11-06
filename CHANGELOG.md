# Changelog

- **Format:** Based on [Keep a Changelog](https://keepachangelog.com).
- **Voice:** Use the imperative, like a commit message. Write add, fix, increase, force, not added, fixed, increased, forced.
- **Length:** Keep each bullet on one line, max 120 characters (link URLs do not count toward the cap, only the visible text does).
- **Links:** Add inline markdown links for related PRs, docs, and external references when they help the reader.

## [Unreleased]

### Changed

- Update `wp-cli/ability-command` to 1.0.4 ([#68](https://github.com/marcop135/wp-agent-harness/pull/68)).
- Cache the site's images for one day instead of one year, so a replaced `og.png` or favicon shows up ([#68](https://github.com/marcop135/wp-agent-harness/pull/68)).
- Link the website's docs to `main` instead of `develop` ([#68](https://github.com/marcop135/wp-agent-harness/pull/68)).

### Fixed

- Remove only the project's own MCP registration in `./bin/connect` and `./bin/reset`, never a user-scope server ([#68](https://github.com/marcop135/wp-agent-harness/pull/68)).
- Stop `./bin/reset --help` and `./bin/connect --help` printing a line of code ([#68](https://github.com/marcop135/wp-agent-harness/pull/68)).
- Fix the WordPress image version command in the dependency update guide ([#68](https://github.com/marcop135/wp-agent-harness/pull/68)).

### Security

- Block WordPress ability calls in Claude Code when `jq` is missing, instead of letting them run ([#68](https://github.com/marcop135/wp-agent-harness/pull/68), [#67](https://github.com/marcop135/wp-agent-harness/issues/67)).
- Require `jq` in `./bin/setup` and fail the loopback port check without it ([#68](https://github.com/marcop135/wp-agent-harness/pull/68)).

## [0.12.0] - 2026-11-05

### Changed

- Move site analytics to a cookieless Matomo Tag Manager container, adding time on page and errors ([#65](https://github.com/marcop135/wp-agent-harness/pull/65), [#64](https://github.com/marcop135/wp-agent-harness/issues/64)).
- List anonymous interaction events in the site's privacy page ([#65](https://github.com/marcop135/wp-agent-harness/pull/65)).

## [0.11.2] - 2026-11-03

### Security

- Require approval for malformed hook payloads and unknown abilities, including unrecognized `get-*` names ([#62](https://github.com/marcop135/wp-agent-harness/pull/62)).

## [0.11.1] - 2026-10-30

### Changed

- Share one WordPress skills copy across Claude Code, Cursor, and Codex ([#59](https://github.com/marcop135/wp-agent-harness/pull/59), [#58](https://github.com/marcop135/wp-agent-harness/issues/58)).

### Fixed

- Correct the copyright holder in `LICENSE` and `NOTICE` ([#60](https://github.com/marcop135/wp-agent-harness/pull/60)).

## [0.11.0] - 2026-10-24

### Added

- Add [abilities reference](docs/abilities.md) ([#52](https://github.com/marcop135/wp-agent-harness/pull/52)).
- Add website FAQ on wp-env, Playground, and login ([#52](https://github.com/marcop135/wp-agent-harness/pull/52)).

### Changed

- Bump WordPress to 7.1.3 ([#52](https://github.com/marcop135/wp-agent-harness/pull/52)).
- Skip Netlify builds; the host only redirects ([#52](https://github.com/marcop135/wp-agent-harness/pull/52)).
- Report MS WordPress Abilities vulnerabilities here: upstream has no private channel ([SECURITY.md](SECURITY.md)) ([#52](https://github.com/marcop135/wp-agent-harness/pull/52)).

## [0.10.2] - 2026-10-24

### Changed

- Refer to MS WP Abilities by name in docs, examples, and issue templates, with its upstream links in `NOTICE` ([#50](https://github.com/marcop135/wp-agent-harness/pull/50)).

### Fixed

- Name the admin login a write runs as in the approval prompt (`WP_ADMIN_USER`) and drop the plugin namespace ([#50](https://github.com/marcop135/wp-agent-harness/pull/50), [#56](https://github.com/marcop135/wp-agent-harness/issues/56)).

## [0.10.1] - 2026-10-23

### Fixed

- Name the connected WordPress user in approval prompts; keep the plugin namespace separate ([#47](https://github.com/marcop135/wp-agent-harness/pull/47), [#56](https://github.com/marcop135/wp-agent-harness/issues/56)).

## [0.10.0] - 2026-10-23

### Changed

- Animate the website title, Quick start, and request flow ([#45](https://github.com/marcop135/wp-agent-harness/pull/45)).
- Add a closing "Run it on your machine" section to the website ([#45](https://github.com/marcop135/wp-agent-harness/pull/45)).
- Show the animated request flow in the README, linked to the website ([#45](https://github.com/marcop135/wp-agent-harness/pull/45)).

## [0.9.0] - 2026-10-22

### Added

- Add a write approval gate: Claude Code and Cursor ask before every write ability ([security](docs/security.md#the-approval-gate)) ([#43](https://github.com/marcop135/wp-agent-harness/pull/43), [#56](https://github.com/marcop135/wp-agent-harness/issues/56)).
- Add `./bin/audit` to list the writes agents made, and `./bin/seed` for demo content (`--remove` deletes it) ([#43](https://github.com/marcop135/wp-agent-harness/pull/43)).
- Test the gate in layer 0, and against the plugin's policy table and audit log in layer 3 ([#43](https://github.com/marcop135/wp-agent-harness/pull/43), [#56](https://github.com/marcop135/wp-agent-harness/issues/56)).

### Changed

- Rework the README and website around the request flow: example prompts, diagram, icon tiles, redrawn images ([#43](https://github.com/marcop135/wp-agent-harness/pull/43)).
- Use request-path tables in docs and examples, and document the gate for live sites ([#43](https://github.com/marcop135/wp-agent-harness/pull/43), [#56](https://github.com/marcop135/wp-agent-harness/issues/56)).
- Run test layer 4 without project settings, since a headless turn cannot answer the approval gate ([#43](https://github.com/marcop135/wp-agent-harness/pull/43), [#56](https://github.com/marcop135/wp-agent-harness/issues/56)).

## [0.8.1] - 2026-10-18

### Changed

- Update MS WP Abilities to 1.13.0, letting `create-post` credit a named author ([#41](https://github.com/marcop135/wp-agent-harness/pull/41)).

## [0.8.0] - 2026-10-17

### Added

- Add a copy button to the website's quick-start snippet and to each example prompt ([#39](https://github.com/marcop135/wp-agent-harness/pull/39)).
- Add a "How a request travels" section tracing agent, MCP Adapter, Abilities API, and WordPress ([#39](https://github.com/marcop135/wp-agent-harness/pull/39)).
- Add six copy-ready prompts from [examples/](https://github.com/marcop135/wp-agent-harness/tree/develop/examples) to the website ([#39](https://github.com/marcop135/wp-agent-harness/pull/39)).
- Add website FAQ answers on agent writes and on pointing an agent at a live site ([#39](https://github.com/marcop135/wp-agent-harness/pull/39)).

### Changed

- Animate website FAQ answers as they open and close, honouring reduced motion ([#39](https://github.com/marcop135/wp-agent-harness/pull/39)).
- Show a "Development only" note and the maintainer above the website footer links on every page ([#39](https://github.com/marcop135/wp-agent-harness/pull/39)).
- Expand the website's feature grid to six items and show the pinned versions in the hero ([#39](https://github.com/marcop135/wp-agent-harness/pull/39)).

## [0.7.3] - 2026-10-16

### Fixed

- Report self-hosted Matomo page views to this site's own property instead of the shared one ([#37](https://github.com/marcop135/wp-agent-harness/pull/37), [#57](https://github.com/marcop135/wp-agent-harness/issues/57)).

## [0.7.2] - 2026-10-16

### Security

- Update [MCP Adapter to 0.7.1](https://github.com/WordPress/mcp-adapter/releases/tag/v0.7.1) to limit stored session data ([#35](https://github.com/marcop135/wp-agent-harness/pull/35)).

## [0.7.1] - 2026-10-16

### Changed

- Redirect every Netlify path to [wpagent.marcopontili.com](https://wpagent.marcopontili.com) with a forced 301 ([#31](https://github.com/marcop135/wp-agent-harness/pull/31), [#57](https://github.com/marcop135/wp-agent-harness/issues/57)).

## [0.7.0] - 2026-10-16

### Added

- Add `site/.htaccess` (headers, CSP, caching, compression) and a `deploy.yml` that mirrors only `site/` ([#32](https://github.com/marcop135/wp-agent-harness/pull/32), [#57](https://github.com/marcop135/wp-agent-harness/issues/57)).
- Add cookieless self-hosted Matomo with a matching CSP and a rewritten privacy notice ([#32](https://github.com/marcop135/wp-agent-harness/pull/32), [#57](https://github.com/marcop135/wp-agent-harness/issues/57)).

### Changed

- Move the website to [wpagent.marcopontili.com](https://wpagent.marcopontili.com) on Netsons; Netlify stays for previews ([#32](https://github.com/marcop135/wp-agent-harness/pull/32), [#57](https://github.com/marcop135/wp-agent-harness/issues/57)).
- Redesign the website: editorial layout, architecture diagram, copyable quick-start blocks, light and dark ([#32](https://github.com/marcop135/wp-agent-harness/pull/32), [#57](https://github.com/marcop135/wp-agent-harness/issues/57)).

## [0.6.0] - 2026-10-13

### Changed

- Rename the display name to Agent Harness for WordPress ([#30](https://github.com/marcop135/wp-agent-harness/pull/30)).

### Fixed

- Marketing site: stop hero grid drift ([#30](https://github.com/marcop135/wp-agent-harness/pull/30)).

## [0.5.1] - 2026-10-13

### Fixed

- Close Website Spec gaps on the Netlify marketing site (404/privacy, headers, contrast, a11y, caching) ([#29](https://github.com/marcop135/wp-agent-harness/pull/29)).

## [0.5.0] - 2026-10-13

### Added

- Add a public marketing site in [`site/`](site/) (Netlify, Prism, favicons, JSON-LD/FAQ/sitemap/`llms.txt`) ([#27](https://github.com/marcop135/wp-agent-harness/pull/27), [#57](https://github.com/marcop135/wp-agent-harness/issues/57)).

## [0.4.5] - 2026-10-09

### Changed

- Redraw `.github/brand/og.png` in the light README header design ([#20](https://github.com/marcop135/wp-agent-harness/pull/20)).
- Re-render the README and social PNGs with the pinned render toolchain ([#20](https://github.com/marcop135/wp-agent-harness/pull/20)).

## [0.4.4] - 2026-10-08

### Added

- Add [`docs/remote-site.md`](docs/remote-site.md): connect an agent to a live WordPress site, outside the harness ([#24](https://github.com/marcop135/wp-agent-harness/pull/24)).

### Changed

- Restructure `docs/` for scanning: symptom index in troubleshooting, tables over prose, shorter sentences ([#24](https://github.com/marcop135/wp-agent-harness/pull/24)).
- Scope the localhost-only boundary to the harness in `CLAUDE.md`, `AGENTS.md` mirrors, and `llms.txt` ([#24](https://github.com/marcop135/wp-agent-harness/pull/24)).

### Fixed

- Correct docs: five test layers, branch from `develop`, public repo, Apache mod_php (not PHP-FPM) ([#24](https://github.com/marcop135/wp-agent-harness/pull/24)).
- Correct the layer 0 description: it compares `.env.example` with `docs/development.md`, not the README ([#24](https://github.com/marcop135/wp-agent-harness/pull/24)).

## [0.4.3] - 2026-10-08

### Changed

- Make `./bin/reset` remove all of `.secrets/` and the Claude Code MCP registration ([#20](https://github.com/marcop135/wp-agent-harness/pull/20)).
- Warn on `./bin/connect --print` that stdout carries a live Basic auth header ([#20](https://github.com/marcop135/wp-agent-harness/pull/20)).

### Fixed

- Correct [`CLAUDE.md`](CLAUDE.md): `--skip-claude` runs layers 0–3, not 1–3 ([#20](https://github.com/marcop135/wp-agent-harness/pull/20)).

### Security

- Verify SHA-256 checksums for the MCP Adapter, MS WP Abilities, and `ability-command` downloads ([#20](https://github.com/marcop135/wp-agent-harness/pull/20), [#55](https://github.com/marcop135/wp-agent-harness/issues/55)).
- Refuse non-loopback port bindings and `network_mode: host` in `./bin/setup` and `./bin/status` ([#20](https://github.com/marcop135/wp-agent-harness/pull/20), [#55](https://github.com/marcop135/wp-agent-harness/issues/55)).
- Enforce mode `600` on `.env` and the Application Password, and `700` on `.secrets/`, where modes apply ([#20](https://github.com/marcop135/wp-agent-harness/pull/20), [#55](https://github.com/marcop135/wp-agent-harness/issues/55)).

## [0.4.2] - 2026-10-05

### Changed

- Standardize the changelog on Format/Voice/Length/Links, inline links, and KaC section order ([#12](https://github.com/marcop135/wp-agent-harness/pull/12), [#16](https://github.com/marcop135/wp-agent-harness/pull/16)).

## [0.4.1] - 2026-10-02

### Changed

- MCP Adapter pin 0.6.1 → 0.7.0 ([#9](https://github.com/marcop135/wp-agent-harness/pull/9)).

## [0.4.0] - 2026-10-01

### Added

- [`NOTICE`](https://github.com/marcop135/wp-agent-harness/blob/develop/NOTICE) for third-party and runtime licence notes (vendored skills, setup installs) ([#7](https://github.com/marcop135/wp-agent-harness/pull/7)).
- CI status badge on the README ([#7](https://github.com/marcop135/wp-agent-harness/pull/7)).

### Changed

- [`LICENSE`](https://github.com/marcop135/wp-agent-harness/blob/develop/LICENSE) is pure MIT so GitHub detects SPDX MIT; third-party notes live in [`NOTICE`](https://github.com/marcop135/wp-agent-harness/blob/develop/NOTICE) ([#7](https://github.com/marcop135/wp-agent-harness/pull/7)).
- README License badge/heading; License section links [`NOTICE`](https://github.com/marcop135/wp-agent-harness/blob/develop/NOTICE) and Dependencies ([#7](https://github.com/marcop135/wp-agent-harness/pull/7)).
- [`CONTRIBUTING.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/CONTRIBUTING.md) requirements link points at [`docs/development.md#requirements`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/development.md#requirements) ([#7](https://github.com/marcop135/wp-agent-harness/pull/7)).

### Removed

- `docs/wp-admin-plugins.png` README screenshot (redundant with version pins and badges) ([#7](https://github.com/marcop135/wp-agent-harness/pull/7)).

## [0.3.0] - 2026-10-01

### Added

- README screenshot of the wp-admin Plugins screen (`docs/wp-admin-plugins.png`) ([#3](https://github.com/marcop135/wp-agent-harness/pull/3)).
- [`.github/brand/`](https://github.com/marcop135/wp-agent-harness/blob/develop/.github/brand/): README, OG and GitHub social images as SVG source + PNG in Catamaran, Cabin and Roboto Mono, rendered by `render.mjs` (`--check` for staleness) ([#3](https://github.com/marcop135/wp-agent-harness/pull/3)).

### Changed

- WordPress pinned to 7.1.2 (`wordpress:7.1.2-php8.3-apache`) ([#4](https://github.com/marcop135/wp-agent-harness/pull/4)).
- [`docs/development.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/development.md): a `WORDPRESS_IMAGE` bump needs `./bin/wp core update`, since core lives in the volume ([#4](https://github.com/marcop135/wp-agent-harness/pull/4)).

### Removed

- `docs/hero.png`, `docs/og.png`, `docs/og.svg`, replaced by [`.github/brand/readme.png`](https://github.com/marcop135/wp-agent-harness/blob/develop/.github/brand/readme.png), `og.png` and `social.png` ([#3](https://github.com/marcop135/wp-agent-harness/pull/3)).

## [0.2.0] - 2026-09-29

### Added

- Agent docs: [`AGENTS.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/AGENTS.md), [`docs/AGENTS.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/AGENTS.md), [`.cursor/AGENTS.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/.cursor/AGENTS.md), [`llms.txt`](https://github.com/marcop135/wp-agent-harness/blob/develop/llms.txt), [`docs/ai-skills.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/ai-skills.md), [`docs/agents/`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/agents/) ([#2](https://github.com/marcop135/wp-agent-harness/pull/2)).
- Codex MCP: [`.codex/config.toml`](https://github.com/marcop135/wp-agent-harness/blob/develop/.codex/config.toml), [`docs/codex.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/codex.md); `./bin/connect --print` works without Claude and exports `WORDPRESS_MCP_BASIC_AUTH` ([#2](https://github.com/marcop135/wp-agent-harness/pull/2), [#54](https://github.com/marcop135/wp-agent-harness/issues/54)).
- README hero/OG assets and static shields (WordPress, MariaDB, Docker Compose, MCP Adapter, MS Abilities) ([#2](https://github.com/marcop135/wp-agent-harness/pull/2)).

### Changed

- README trimmed; requirements, commands, URLs, versions, and test layers live in [`docs/development.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/development.md) ([#2](https://github.com/marcop135/wp-agent-harness/pull/2)).
- Multi-agent quick start (Claude Code, Cursor, Codex) ([#2](https://github.com/marcop135/wp-agent-harness/pull/2), [#54](https://github.com/marcop135/wp-agent-harness/issues/54)).
- [`CLAUDE.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/CLAUDE.md) points at [`docs/AGENTS.md`](https://github.com/marcop135/wp-agent-harness/blob/develop/docs/AGENTS.md); architecture tree lists agent entry files and social assets ([#2](https://github.com/marcop135/wp-agent-harness/pull/2)).

## [0.1.0] - 2026-09-28

### Added

- Docker Compose stack (WordPress 7.1 / PHP 8.3 / MariaDB 11.8), loopback-only ports, [`./bin/setup`](https://github.com/marcop135/wp-agent-harness/blob/develop/bin/setup), [`./bin/reset`](https://github.com/marcop135/wp-agent-harness/blob/develop/bin/reset).
- Pinned MCP Adapter and MS WordPress Abilities; WP-CLI plus `wp-cli/ability-command` in the image.
- Application Password wiring and [`./bin/connect`](https://github.com/marcop135/wp-agent-harness/blob/develop/bin/connect) for Claude Code.
- Four test layers: repository, smoke, MCP, optional headless Claude Code.
- Curated WordPress agent skills under [`.claude/skills/`](https://github.com/marcop135/wp-agent-harness/blob/develop/.claude/skills/) and [`.cursor/skills/`](https://github.com/marcop135/wp-agent-harness/blob/develop/.cursor/skills/).
