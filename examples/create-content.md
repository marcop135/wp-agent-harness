# Creating content

Writes to the site. Everything below creates drafts, never published pages.

## Prompt

> Create a draft page called "About This Site". Use Gutenberg-compatible content
> with a heading, two paragraphs, and a list. Do not publish it.

## Abilities used

| Ability | For |
|---------|-----|
| `miriamschwab/create-post` | creating the page |
| `miriamschwab/get-pages` | reading it back |

## What happens

`create-post` takes `markdown` and converts it to native Gutenberg blocks
server-side, so the cleanest route is markdown in, blocks out:

```json
{
  "title": "About This Site",
  "post_type": "page",
  "status": "draft",
  "markdown": "## About this site\n\nFirst paragraph.\n\nSecond paragraph.\n\n- one\n- two\n- three\n"
}
```

It returns the post ID, permalink, edit link and status. The stored content is
real block markup:

```html
<!-- wp:heading --><h2 class="wp-block-heading">About this site</h2><!-- /wp:heading -->
<!-- wp:paragraph --><p>First paragraph.</p><!-- /wp:paragraph -->
<!-- wp:list --><ul class="wp-block-list">…</ul><!-- /wp:list -->
```

Check it yourself:

```bash
./bin/wp post list --post_type=page --post_status=draft --fields=ID,post_title
./bin/wp post get <ID> --field=content
```

Open it in the block editor at `http://localhost:8080/wp-admin/post.php?post=<ID>&action=edit`
— the blocks are native, with no "unexpected content" warning.

## Notes on the input

- `status` defaults to `draft`. Leave it alone unless you mean to publish.
- `post_type` defaults to `post`; pass `page` for a page.
- `content` takes raw HTML and is ignored when `markdown` is present. Prefer
  `markdown` — hand-written block comments are easy to get subtly wrong.
- `categories` and `tags` take **names**, not IDs, and only attach terms that
  already exist. Create missing ones first with `miriamschwab/create-term`.
- `meta` sets post meta on creation, including Yoast fields
  (`_yoast_wpseo_title`, `_yoast_wpseo_metadesc`, `_yoast_wpseo_focuskw`).

## Variants

> Create a draft post titled "Release notes" in the category "Updates", tagged
> "changelog", with a short intro paragraph and a three-item list. Create the
> category and tag first if they do not exist.

> Create three draft pages — Services, Pricing and Contact — each with a heading
> and one placeholder paragraph. Make Pricing and Contact children of Services.

Page hierarchy is not a `create-post` parameter; Claude will create the pages
and then set `post_parent` through `miriamschwab/rest-write` on
`/wp/v2/pages/<id>`. It should tell you that is what it is doing before doing it.

## The reproducible demonstration

This is the flow `./bin/test claude-code` automates. Run it by hand to watch it
happen:

1. **Inspect**
   > Inspect this WordPress site and tell me its version, active theme and active plugins.

2. **Create**
   > Create a draft page titled exactly "MCP Integration Test", with a heading
   > "Written by Claude Code" and one paragraph saying it was created through the
   > Model Context Protocol. Keep it a draft.

3. **Read back**
   > Find the draft page "MCP Integration Test" and tell me its ID, status and heading.

4. **Modify**
   > In that page, replace the phrase "Written by Claude Code" with "Verified by
   > Claude Code". Change nothing else.

5. **Verify**
   > Read the page back and confirm the heading now says "Verified by Claude Code".

6. **Clean up**
   > Move that page to the trash and confirm its new status.

At each step, check the database directly:

```bash
ID=$(./bin/wp post list --post_type=page --post_status=any,trash \
       --title='MCP Integration Test' --field=ID --format=csv)
./bin/wp post get "$ID" --fields=ID,post_title,post_status
./bin/wp post get "$ID" --field=content
```

Then remove it for good:

```bash
./bin/wp post delete "$ID" --force
```

`trash-post` is deliberately the most destructive content ability exposed —
there is no permanent delete over MCP, and `rest-write` hard-blocks
`force=true`.
