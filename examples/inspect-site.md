# Site inspection

Read-only. Safe to run at any time.

## Prompt

> Inspect the local WordPress site. Tell me the WordPress version, active theme,
> active plugins, site title, available post types, and current content
> structure.

## Abilities used

| Ability | For |
|---------|-----|
| `core/get-site-info` | site title, URL, WordPress version |
| `core/get-environment-info` | environment type, PHP and database versions |
| `miriamschwab/get-site-settings` | title, tagline, timezone, date format, posts per page, language, active theme |
| `miriamschwab/get-themes` | installed themes, versions, which is active |
| `miriamschwab/get-plugins` | installed plugins, active state, pending updates |
| `miriamschwab/get-post-types` | registered public post types |
| `miriamschwab/get-posts`, `get-pages` | what content exists |

## What you should see

On a freshly provisioned site:

- WordPress 7.1.2, PHP 8.3, MariaDB 11.8.9, environment type `local`
- Active theme **Twenty Twenty-Five 1.5**
- Exactly two plugins, both active: **MCP Adapter 0.7.0** and **MS WordPress Abilities 1.12.0**
- Post types `post`, `page`, `attachment`
- The stock WordPress content: one post, a sample page, a privacy policy draft

Claude will make several tool calls to assemble this — it has to fetch the
schema of an ability before executing it the first time.

## Narrower variants

> What environment type does this WordPress site report, and what PHP and
> database versions is it running on?

> List every registered post type with its labels, and say which ones are public.

> Show me the navigation menus and their items.

The last one uses `miriamschwab/get-menus`. A fresh Twenty Twenty-Five install
has no classic menus — navigation lives in a `wp_navigation` post — so an empty
result is correct, not a failure.

## Verifying it independently

Every claim above can be checked without MCP:

```bash
./bin/wp core version
./bin/wp theme list
./bin/wp plugin list
./bin/wp post-type list
./bin/wp ability run core/get-site-info --user=admin
```

If WP-CLI and Claude disagree, trust WP-CLI and read
[docs/troubleshooting.md](../docs/troubleshooting.md).
