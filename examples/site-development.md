# Site development

A feature built on what the site already has. Writes drafts; the approval gate
asks before each write.

> Build a Services page with three child pages, as drafts. Show me the structure
> first.

A fuller version:

> Build a Services section: a top-level "Services" page with a short intro, and
> three child pages, Consulting, Training and Support, each with a heading, one
> paragraph and a three-item list. Keep everything as drafts and show me the
> structure before you start.

| Ability | Used for | Type |
|---------|----------|------|
| `get-site-settings`, `get-post-types`, `get-pages`, `get-themes` | what exists and which conventions the site follows | read |
| `create-post` | one draft per page, markdown converted to blocks | write, gate asks |
| `rest-write` | `post_parent` on `/wp/v2/pages/<id>`; hierarchy is not a `create-post` parameter | write, gate asks |
| `rest-get` | anything another plugin registers | read |

## What you should see

1. Inspection reads first
2. A plain-text proposal: page tree, block structure, drafts only
3. One `create-post` per page, then `rest-write` for the hierarchy, announced first
4. The tree read back with `get-pages`, with IDs

## Verify

```bash
./bin/wp post list --post_type=page --post_status=draft --fields=ID,post_title,post_parent
./bin/audit
```

## What is reachable

The 26 MS WP Abilities cover content, taxonomy, media, settings, plugins and
themes; `rest-get` and `rest-write` cover any other REST route. That is why this
repository adds no abilities of its own
([docs/architecture.md](../docs/architecture.md#design-decisions)). When the
agent calls something impossible, push back:

> Check `/wp/v2` and the plugin's own namespace with rest-get before concluding
> that.

| Layer | Reachable over MCP | How |
|-------|--------------------|-----|
| Content, taxonomy, media, menus | yes | MS WP Abilities |
| Site settings | read only | `get-site-settings`; writes to `/wp/v2/settings` are hard-blocked |
| Templates and global styles | yes | `rest-write` on `/wp/v2/templates`, `/wp/v2/global-styles` |
| Plugin install, activate, update | yes | `install-plugin`, `activate-plugin`, `update-plugin` |
| Theme and plugin **source files** | no | bind-mount and edit on the host |
| Docker, `bin/`, `.env` | no, and should not be | [docs/development.md](../docs/development.md) |

`CLAUDE.md` tells Claude Code the same. If it starts editing
`docker-compose.yml` for a content feature, stop it.

## Follow-ups

> Add an FAQ section to the Services page using the theme's existing block
> patterns rather than hand-written markup. Show me which pattern you picked.

> Audit every published page for missing excerpts and propose one for each, based
> on its first paragraph. Show me the list before writing anything.

> Create a "Case studies" custom taxonomy.

Not possible over MCP: a taxonomy needs PHP in a plugin or theme. The agent
should say so and offer the file for you to place via a bind mount.

> Set up the site's front page to be the static "Home" page rather than the blog.

Needs `show_on_front` and `page_on_front` in `/wp/v2/settings`, which
`rest-write` hard-blocks. The correct outcome is the agent naming the wall and
handing you the commands:

```bash
./bin/wp option update show_on_front page
./bin/wp option update page_on_front <ID>
```

## Keeping the work

The database is destroyed by `./bin/reset`. Export a result to `tmp/`
(git-ignored):

```bash
./bin/wp post list --post_type=page --format=json > tmp/pages.json
./bin/wp db export - > tmp/snapshot.sql
```

What should survive a reset belongs in `docker/wordpress/bin/wp-provision`, not
in a database dump.
