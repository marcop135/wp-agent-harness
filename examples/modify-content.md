# Modifying content

Writes to the site. Read what Claude proposes before agreeing to it.

## Prompt

> Find the draft page "About This Site" and improve its structure without
> changing its meaning. Show me the intended changes before applying them.

## Abilities used

| Ability | For |
|---------|-----|
| `miriamschwab/get-pages` | finding the page |
| `miriamschwab/preview-post-update` | staging the change and returning a before/after diff |
| `miriamschwab/apply-post-update` | committing the staged change |
| `miriamschwab/patch-post-content` | a targeted find-and-replace, no staging |

## The two write paths

**Staged, for substantial rewrites.** `preview-post-update` writes the proposal
into user meta and returns a diff without touching the post.
`apply-post-update` commits it, taking only `post_id`. The staged update belongs
to the authenticated user and expires after ten minutes.

**Surgical, for small edits.** `patch-post-content` takes `post_id`, `find`,
`replace` and an optional `replace_all`. It fails if `find` is not present, so a
typo in the search string cannot silently do nothing. It returns the number of
replacements.

Claude should pick the second for "fix this typo" and the first for "restructure
this page".

## What the confirmation actually is

The ability descriptions instruct the agent to state the proposed change in
plain language and wait for your explicit approval. That is a convention between
you and the model. `apply-post-update` only checks that a preview was staged, by
the same user, recently — it has no idea whether a human saw it. Read the
proposal. See [docs/security.md](../docs/security.md).

## Variants

> In the draft page "About This Site", change "we provide" to "we offer"
> everywhere it appears. Nothing else.

Uses `patch-post-content` with `replace_all: true`.

> The draft page "About This Site" has one long paragraph. Split it into three,
> add an H2 above each, and keep the wording identical. Show me the diff first.

Uses the staged path.

> Add a link to the Contact page in the last paragraph of "About This Site".

`patch-post-content`, replacing a known sentence with the same sentence plus an
anchor. Claude needs the Contact page's permalink first, so expect a `get-pages`
call.

## Verifying

```bash
ID=$(./bin/wp post list --post_type=page --title='About This Site' --field=ID --format=csv)
./bin/wp post get "$ID" --field=content
./bin/wp post list --post_type=revision --post_parent="$ID" --fields=ID,post_date
```

Both write paths go through `wp_update_post()`, so WordPress keeps revisions.
Any change made here is recoverable from **Revisions** in the block editor —
which is the practical reason to let Claude write drafts rather than publish.

## Undoing

```bash
./bin/wp post list --post_type=revision --post_parent="$ID" --fields=ID,post_date
./bin/wp eval 'wp_restore_post_revision( <REVISION_ID> );'
```
