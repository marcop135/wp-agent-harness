# Site inspection

Read-only: the approval gate never asks. With `./bin/seed` run, the content
report includes the Harbor Coffee pages, posts and categories.

> Inspect the local WordPress site. Tell me the WordPress version, active theme,
> active plugins, site title, available post types, and current content
> structure.

| Ability | Used for | Type |
|---------|----------|------|
| `core/get-site-info` | site title, URL, WordPress version | read |
| `core/get-environment-info` | environment type, PHP and database versions | read |
| `get-site-settings` | title, tagline, timezone, date format, posts per page, language, active theme | read |
| `get-themes` | installed themes, versions, which is active | read |
| `get-plugins` | installed plugins, active state, pending updates | read |
| `get-post-types` | registered public post types | read |
| `get-posts`, `get-pages` | what content exists | read |

## What you should see

- WordPress 7.1.3, PHP 8.3, MariaDB 11.8.9, environment type `local`
- Active theme **Twenty Twenty-Five 1.5**
- Exactly two plugins, both active: **MCP Adapter 0.7.1** and **MS WordPress Abilities 1.13.0**
- Post types `post`, `page`, `attachment`
- Stock content: one post, a sample page, a privacy policy draft; plus the seed content if loaded
- Several tool calls: the agent fetches an ability's schema before executing it the first time

## Verify

```bash
./bin/wp core version
./bin/wp theme list
./bin/wp plugin list
./bin/wp post-type list
./bin/wp ability run core/get-site-info --user=admin
```

If WP-CLI and the agent disagree, trust WP-CLI and read
[docs/troubleshooting.md](../docs/troubleshooting.md).

## Follow-ups

> What environment type does this WordPress site report, and what PHP and
> database versions is it running on?

> List every registered post type with its labels, and say which ones are public.

> Show me the navigation menus and their items.

The last uses `get-menus`. Twenty Twenty-Five keeps navigation in a
`wp_navigation` post, not a classic menu, so an empty result is correct.
