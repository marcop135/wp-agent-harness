# Theme inspection

Read-only.

## Prompt

> Inspect the active Twenty Twenty-Five theme and explain its current template
> structure and available templates.

## Abilities used

| Ability | For |
|---------|-----|
| `miriamschwab/get-themes` | installed themes, versions, which is active |
| `miriamschwab/rest-get` | the block-theme endpoints below |

There is no dedicated "read the theme's files" ability. Twenty Twenty-Five is a
block theme, so its templates, template parts and global styles are all exposed
through the REST API, and `rest-get` is the right way in:

| Route | Returns |
|-------|---------|
| `/wp/v2/templates` | every template, theme-provided and user-edited |
| `/wp/v2/template-parts` | header, footer and other parts |
| `/wp/v2/global-styles/themes/twentytwentyfive` | `theme.json` settings and styles |
| `/wp/v2/block-types` | the blocks available to build with |
| `/wp/v2/block-patterns/patterns` | the theme's registered patterns |

## What you should see

Twenty Twenty-Five 1.5 ships around twenty templates — `index`, `home`,
`single`, `page`, `archive`, `search`, `404`, `page-no-title`, several
`single-post-*` variants — plus header, footer and post-meta template parts, and
a large pattern library.

A template's `source` is `theme` until someone edits it in the Site Editor, at
which point a `wp_template` post is created and `source` becomes `custom`. That
distinction is worth asking about:

> Which Twenty Twenty-Five templates have been customised in the Site Editor,
> and which are still coming from the theme?

## Variants

> Show me Twenty Twenty-Five's colour palette and typography settings from
> theme.json.

`rest-get /wp/v2/global-styles/themes/twentytwentyfive`.

> List the template parts and explain what each is used for.

> Which block patterns does Twenty Twenty-Five register, and which are intended
> for the home page?

## Reading the files themselves

The theme lives in the container, not in this repository:

```bash
docker compose exec wordpress ls /var/www/html/wp-content/themes/twentytwentyfive/templates
docker compose exec wordpress ls /var/www/html/wp-content/themes/twentytwentyfive/parts
docker compose exec wordpress cat /var/www/html/wp-content/themes/twentytwentyfive/theme.json

# copy it out to read on the host
docker compose cp wordpress:/var/www/html/wp-content/themes/twentytwentyfive ./tmp/
```

To work on theme source from your editor, bind-mount it — see
[docs/development.md](../docs/development.md#working-on-plugin-or-theme-source).

## Changing the theme

`miriamschwab/update-theme` updates a theme to its latest version. There is no
ability that writes template files. Site Editor changes made in the browser show
up as `source: custom` templates, which Claude can then read back through
`/wp/v2/templates` and, with `rest-write`, modify. Ask for the change to be
stated first — that is an edit to what the site renders.
