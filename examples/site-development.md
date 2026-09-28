# Site development

The open-ended case: a real feature, built on what the site already has.

## Prompt

> Inspect the current WordPress site and implement the requested feature using
> the existing WordPress architecture. Do not modify infrastructure unless
> necessary.

That prompt is a frame, not a task. Give it something to build:

> Build a Services section: a top-level "Services" page with a short intro, and
> three child pages — Consulting, Training and Support — each with a heading, one
> paragraph and a three-item list. Keep everything as drafts and show me the
> structure before you start.

## What a good run looks like

1. **Inspect first.** `get-site-settings`, `get-post-types`, `get-pages`,
   `get-themes` — what exists, what the theme provides, what conventions the
   site already follows.
2. **Propose.** The page tree, the block structure, what will be a draft. In
   plain text, before any write.
3. **Build.** `create-post` per page, markdown converted to native blocks.
4. **Wire it up.** Hierarchy is not a `create-post` parameter, so `post_parent`
   goes through `rest-write` on `/wp/v2/pages/<id>`. Claude should say so first.
5. **Verify.** Read the tree back with `get-pages` and report the IDs.

## Why this works without a custom ability

The 26 MS WP Abilities cover content, taxonomy, media, settings, plugins and
themes. `rest-get` and `rest-write` cover everything else any plugin registers.
Between them there is very little a site-building task needs that is out of
reach, which is why this repository adds no abilities of its own — see
[docs/architecture.md](../docs/architecture.md#design-decisions).

When Claude thinks something is impossible, the usual answer is that it has not
looked at the right REST namespace. Most plugins register one matching their
slug. Push back:

> Check `/wp/v2` and the plugin's own namespace with rest-get before concluding
> that.

## Scope boundaries

Say which of these you mean:

| Layer | Reachable over MCP | How |
|-------|--------------------|-----|
| Content, taxonomy, media, menus | yes | MS WP Abilities |
| Site settings | read only | `get-site-settings`; writes to `/wp/v2/settings` are hard-blocked |
| Templates and global styles | yes | `rest-write` on `/wp/v2/templates`, `/wp/v2/global-styles` |
| Plugin install, activate, update | yes | `install-plugin`, `activate-plugin`, `update-plugin` |
| Theme and plugin **source files** | no | bind-mount and edit on the host |
| Docker, `bin/`, `.env` | no, and should not be | [docs/development.md](../docs/development.md) |

`CLAUDE.md` in the repository root tells Claude Code the same thing, so it
should already be treating infrastructure as off-limits for a content task. If
it starts editing `docker-compose.yml` to add a feature, stop it.

## More prompts

> Add an FAQ section to the Services page using the theme's existing block
> patterns rather than hand-written markup. Show me which pattern you picked.

> Create a "Case studies" custom taxonomy… — not possible over MCP. Registering
> a taxonomy needs PHP in a plugin or theme. Claude should say so and offer the
> file it would write, for you to place via a bind mount.

> Audit every published page for missing excerpts and propose one for each, based
> on its first paragraph. Show me the list before writing anything.

> Set up the site's front page to be the static "Home" page rather than the blog.

That last one needs `show_on_front` and `page_on_front` in `/wp/v2/settings`,
which `rest-write` hard-blocks. Claude should say so and give you the command:

```bash
./bin/wp option update show_on_front page
./bin/wp option update page_on_front <ID>
```

Being told exactly where the wall is, and how to get past it yourself, is the
correct outcome — not a workaround.

## Keeping the work

Everything built this way lives in the database, which `./bin/reset` destroys.
To make a result reproducible, export it:

```bash
./bin/wp post list --post_type=page --format=json > tmp/pages.json
./bin/wp db export - > tmp/snapshot.sql
```

`tmp/` is git-ignored. Anything that should survive a reset belongs in
`docker/wordpress/bin/wp-provision`, not in a database dump.
