# Creating content

Writes a draft; the approval gate asks before `create-post`.

> Create a draft page called "About This Site". Use Gutenberg-compatible content
> with a heading, two paragraphs, and a list. Do not publish it.

| Ability | Used for | Type |
|---------|----------|------|
| `miriamschwab/create-post` | creating the page | write, gate asks |
| `miriamschwab/get-pages` | reading it back | read |

`create-post` converts `markdown` to native blocks server-side:

```json
{
  "title": "About This Site",
  "post_type": "page",
  "status": "draft",
  "markdown": "## About this site\n\nFirst paragraph.\n\nSecond paragraph.\n\n- one\n- two\n- three\n"
}
```

Input notes:

- `status` defaults to `draft`; `post_type` defaults to `post`, so pass `page`.
- `content` takes raw HTML and is ignored when `markdown` is present. Prefer
  `markdown`: hand-written block comments are easy to get subtly wrong.
- `categories` and `tags` take **names**, not IDs, and only attach existing
  terms. Create missing ones first with `miriamschwab/create-term`.
- `meta` sets post meta on creation, including Yoast fields
  (`_yoast_wpseo_title`, `_yoast_wpseo_metadesc`, `_yoast_wpseo_focuskw`).

## What you should see

- The post ID, permalink, edit link and status `draft`
- Stored content in real block markup (`<!-- wp:heading -->`, `<!-- wp:paragraph -->`, `<!-- wp:list -->`)
- No "unexpected content" warning at `http://localhost:8080/wp-admin/post.php?post=<ID>&action=edit`

## Verify

```bash
./bin/wp post list --post_type=page --post_status=draft --fields=ID,post_title
./bin/wp post get <ID> --field=content
./bin/audit
```

## Follow-ups

> Create a draft post titled "Release notes" in the category "Updates", tagged
> "changelog", with a short intro paragraph and a three-item list. Create the
> category and tag first if they do not exist.

> Create three draft pages, Services, Pricing and Contact, each with a heading
> and one placeholder paragraph. Make Pricing and Contact children of Services.

Page hierarchy is not a `create-post` parameter: the agent sets `post_parent`
through `miriamschwab/rest-write` on `/wp/v2/pages/<id>` and should say so first.

## End-to-end demonstration

The flow `./bin/test claude-code` automates, by hand:

1. > Inspect this WordPress site and tell me its version, active theme and active plugins.
2. > Create a draft page titled exactly "MCP Integration Test", with a heading
   > "Written by Claude Code" and one paragraph saying it was created through the
   > Model Context Protocol. Keep it a draft.
3. > Find the draft page "MCP Integration Test" and tell me its ID, status and heading.
4. > In that page, replace the phrase "Written by Claude Code" with "Verified by
   > Claude Code". Change nothing else.
5. > Read the page back and confirm the heading now says "Verified by Claude Code".
6. > Move that page to the trash and confirm its new status.

Check each step, then remove the page for good:

```bash
ID=$(./bin/wp post list --post_type=page --post_status=any,trash \
       --title='MCP Integration Test' --field=ID --format=csv)
./bin/wp post get "$ID" --fields=ID,post_title,post_status
./bin/wp post get "$ID" --field=content
./bin/wp post delete "$ID" --force
```

`trash-post` is the most destructive content ability exposed: there is no
permanent delete over MCP, and `rest-write` hard-blocks `force=true`.
