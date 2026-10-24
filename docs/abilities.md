# Abilities

What the agent can do on the local site. [MS WordPress Abilities](https://github.com/miriamschwab/ms-wp-abilities)
1.13.0 registers 26 abilities under `miriamschwab/`, and WordPress core adds 3
under `core/`: 29 over MCP. Descriptions follow the plugin's own.

**Gate** is what the [approval gate](security.md#the-approval-gate) does in
Claude Code and Cursor: `read` runs without asking, `ask` waits for your
approval. Codex uses its own approval settings.

`./bin/wp ability list` prints the live list. Trust it over this page.

## Posts and pages

| Ability | What it does | Gate |
|---------|--------------|------|
| `get-posts` | List posts, filtered by status, post type, category, tag, or search | read |
| `get-pages` | List pages with parent/child hierarchy and menu order | read |
| `get-post-meta` | Read a post's meta, all keys or the ones asked for | read |
| `get-post-types` | List public post types | read |
| `create-post` | Create a post or page, as a draft by default; Markdown becomes native blocks | ask |
| `patch-post-content` | Find and replace inside post content, no preview step | ask |
| `preview-post-update` | Stage an update and return a before/after diff; changes nothing | read |
| `apply-post-update` | Apply an update staged by `preview-post-update` | ask |
| `trash-post` | Move a post or page to the trash, reversible from wp-admin | ask |

## Categories and tags

| Ability | What it does | Gate |
|---------|--------------|------|
| `get-categories` | List categories with slugs, counts, and parents | read |
| `get-tags` | List tags with slugs and counts | read |
| `create-term` | Create a category or tag | ask |

## Media

| Ability | What it does | Gate |
|---------|--------------|------|
| `get-media` | List media items, filtered by MIME type or search | read |
| `update-media-meta` | Set alt text, title, caption, or description | ask |

## Site, users, and menus

| Ability | What it does | Gate |
|---------|--------------|------|
| `get-site-settings` | Read name, tagline, URL, timezone, date format, language, active theme | read |
| `get-users` | List users, optionally by role | read |
| `get-menus` | List navigation menus and their items | read |

## Plugins, themes, and updates

| Ability | What it does | Gate |
|---------|--------------|------|
| `get-plugins` | List installed plugins, active state, and available updates | read |
| `install-plugin` | Install a plugin from WordPress.org by slug; activates only on request | ask |
| `activate-plugin` | Activate an installed plugin | ask |
| `update-plugin` | Update a plugin to its latest version | ask |
| `get-themes` | List installed themes, active state, and available updates | read |
| `update-theme` | Update a theme to its latest version | ask |
| `get-available-updates` | Report plugin, theme, and core updates from cached data | read |

## REST bridge

| Ability | What it does | Gate |
|---------|--------------|------|
| `rest-get` | GET any registered REST route, core or plugin | read |
| `rest-write` | POST, PUT, PATCH, or DELETE any registered REST route | ask |

`rest-write` is hard-blocked, approval or not, on any write to `/wp/v2/users`
or `/wp/v2/settings`, DELETE on `/wp/v2/plugins`, and any `force=true`
permanent delete. See [Security](security.md#capability-checks-and-the-hard-block-list).

## WordPress core

| Ability | What it does | Gate |
|---------|--------------|------|
| `core/get-site-info` | Site name, URL, and other configured site details | read |
| `core/get-user-info` | Profile of the connected user | read |
| `core/get-environment-info` | Environment type, PHP, database, and WordPress versions | read |

Every call runs as the user behind the Application Password, with the same
capability checks as wp-admin. Writes are recorded in the audit log that
`./bin/audit` prints.
