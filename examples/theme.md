# Theme inspection

Read-only: the approval gate never asks.

> Inspect the active Twenty Twenty-Five theme and explain its current template
> structure and available templates.

| Ability | Used for | Type |
|---------|----------|------|
| `miriamschwab/get-themes` | installed themes, versions, which is active | read |
| `miriamschwab/rest-get` | the block-theme routes below | read |

No ability reads theme files. Twenty Twenty-Five is a block theme, so
`rest-get` reaches it through REST:

| Route | Returns |
|-------|---------|
| `/wp/v2/templates` | every template, theme-provided and user-edited |
| `/wp/v2/template-parts` | header, footer and other parts |
| `/wp/v2/global-styles/themes/twentytwentyfive` | `theme.json` settings and styles |
| `/wp/v2/block-types` | the blocks available to build with |
| `/wp/v2/block-patterns/patterns` | the theme's registered patterns |

## What you should see

- About twenty templates: `index`, `home`, `single`, `page`, `archive`,
  `search`, `404`, `page-no-title`, several `single-post-*` variants
- Header, footer and post-meta template parts, and a large pattern library
- `source: theme` on each template until someone edits it in the Site Editor,
  which creates a `wp_template` post with `source: custom`

## Verify

The theme lives in the container, not in this repository:

```bash
./bin/wp theme list
docker compose exec wordpress ls /var/www/html/wp-content/themes/twentytwentyfive/templates
docker compose exec wordpress ls /var/www/html/wp-content/themes/twentytwentyfive/parts
docker compose exec wordpress cat /var/www/html/wp-content/themes/twentytwentyfive/theme.json
docker compose cp wordpress:/var/www/html/wp-content/themes/twentytwentyfive ./tmp/
```

To edit theme source from the host, bind-mount it:
[docs/development.md](../docs/development.md#working-on-plugin-or-theme-source).

## Follow-ups

> Which Twenty Twenty-Five templates have been customised in the Site Editor,
> and which are still coming from the theme?

> Show me Twenty Twenty-Five's colour palette and typography settings from
> theme.json.

> List the template parts and explain what each is used for.

> Which block patterns does Twenty Twenty-Five register, and which are intended
> for the home page?

## Changing the theme

`miriamschwab/update-theme` updates a theme to its latest version (write, gate
asks). No ability writes template files. `source: custom` templates can be
modified with `rest-write` on `/wp/v2/templates`; that changes what the site
renders, so ask for the change to be stated first.
