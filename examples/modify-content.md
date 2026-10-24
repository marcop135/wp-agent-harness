# Modifying content

Writes; the approval gate asks before `apply-post-update` and
`patch-post-content`. `./bin/seed` adds the "Wholesale" draft: one long
unstructured paragraph, ready to restructure.

> Improve the structure of the Wholesale draft without changing its meaning.
> Show me the changes first.

| Ability | Used for | Type |
|---------|----------|------|
| `get-pages` | finding the page | read |
| `preview-post-update` | staging the change, returning a before/after diff | read, no write yet |
| `apply-post-update` | committing the staged change | write, gate asks |
| `patch-post-content` | a targeted find-and-replace, no staging | write, gate asks |

Two write paths:

- **Staged, for rewrites.** `preview-post-update` stores the proposal in user
  meta and returns a diff without touching the post. `apply-post-update` takes
  only `post_id`. The staged update belongs to the authenticated user and
  expires after ten minutes.
- **Surgical, for small edits.** `patch-post-content` takes `post_id`, `find`,
  `replace` and optional `replace_all`. It fails if `find` is absent and returns
  the replacement count.

`apply-post-update` only checks that the same user staged a preview recently,
not that a human read it. The gate asks before the write; read the proposal
before approving. See [docs/security.md](../docs/security.md).

## What you should see

- A plain-language proposal and diff before any write
- The staged path for a restructure, `patch-post-content` for a typo
- Headings and a list in place of the single paragraph, wording kept
- One gate prompt naming `apply-post-update`

## Verify

```bash
ID=$(./bin/wp post list --post_type=page --post_status=draft --title='Wholesale' --field=ID --format=csv)
./bin/wp post get "$ID" --field=content
./bin/wp post list --post_type=revision --post_parent="$ID" --fields=ID,post_date
./bin/audit
```

Both paths go through `wp_update_post()`, so WordPress keeps revisions. To undo:

```bash
./bin/wp eval 'wp_restore_post_revision( <REVISION_ID> );'
```

## Follow-ups

> In the Wholesale draft, change "We supply" to "We roast for" everywhere it
> appears. Nothing else.

Uses `patch-post-content` with `replace_all: true`.

> Add a link to the Contact page in the last sentence of the Wholesale draft.

`patch-post-content`, replacing a known sentence with the same sentence plus an
anchor; expect a `get-pages` call for the Contact permalink first.
