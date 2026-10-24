# Media

The audit is read-only; the alt-text fix writes and the approval gate asks.
`./bin/seed` adds three images: Storefront has alt text, Roastery and Pour-over
have none. A fresh install has an empty media library.

> Find images in the media library with no alt text, and propose some.

| Ability | Used for | Type |
|---------|----------|------|
| `get-media` | listing media items | read |
| `update-media-meta` | setting alt, title, caption, description | write, gate asks |

`get-media` takes `per_page` (default 20), `mime_type` (`image`, `image/jpeg`,
`application/pdf`, ...), `search`, and a `fields` list. Each item carries `ID`,
`title`, `caption`, `alt`, `url`, `mime_type`, `date`, `width`, `height` and
`edit_link`. The audit is one call plus a filter on empty `alt`:

```json
{ "mime_type": "image", "per_page": 100,
  "fields": ["ID", "title", "alt", "url", "mime_type"] }
```

`update-media-meta` requires `ID` and accepts `alt`, `title`, `caption` and
`description`. It has no staging step; the gate prompt is the confirmation.

## What you should see

- Roastery and Pour-over listed as missing alt text; Storefront not
- Proposed alt text for each, before any write
- One gate prompt per `update-media-meta` call
- Without seed content: "there is no media here"

The agent has not seen the images; it guesses from titles and filenames. Treat
the proposals as drafts to review.

## Verify

```bash
./bin/wp post list --post_type=attachment --fields=ID,post_title,post_mime_type
./bin/wp post meta get <ID> _wp_attachment_image_alt
./bin/audit
```

To add your own image instead:

```bash
docker compose cp ./some-image.jpg wordpress:/tmp/some-image.jpg
./bin/wp media import /tmp/some-image.jpg --title="Example image"
```

## Follow-ups

> How many items are in the media library, broken down by MIME type?

> Which uploaded images are wider than 2000px? Those are candidates for resizing.

> Show every PDF in the media library with its title and URL.

> Set the caption on the Storefront image to "Harbor Street on opening day".

No ability uploads, generates or deletes a media item. Uploading is a browser,
WP-CLI (`wp media import`) or `rest-write` job; `rest-write` hard-blocks
`force=true`, so nothing is permanently deleted over MCP in one step.
