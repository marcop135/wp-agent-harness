# Media

Inspection is read-only; the alt-text fix writes.

## Prompt

> Inspect the media library and identify images with missing alt text.

## Abilities used

| Ability | For |
|---------|-----|
| `miriamschwab/get-media` | listing media items |
| `miriamschwab/update-media-meta` | setting alt, title, caption, description |

## What happens

`get-media` takes `per_page` (default 20), `mime_type` (`image`, `image/jpeg`,
`application/pdf`, …), `search`, and a `fields` list to keep the response small.
Each item carries `ID`, `title`, `caption`, `alt`, `url`, `mime_type`, `date`,
`width`, `height` and `edit_link`.

So the audit is one call plus a filter:

```json
{ "mime_type": "image", "per_page": 100,
  "fields": ["ID", "title", "alt", "url", "mime_type"] }
```

Claude reports the items whose `alt` is empty.

**A fresh install has an empty media library**, so the honest first answer is
"there is no media here". Upload something through
`http://localhost:8080/wp-admin/upload.php` first, or:

```bash
docker compose cp ./some-image.jpg wordpress:/tmp/some-image.jpg
./bin/wp media import /tmp/some-image.jpg --title="Example image"
```

## Fixing the alt text

> For each image with no alt text, propose alt text based on its title and
> filename, show me the list, and apply it once I agree.

`update-media-meta` requires `ID` and accepts `alt`, `title`, `caption` and
`description`. It is a direct update with no staging step — metadata changes are
not treated as risky — so the confirmation here is entirely Claude's own
behaviour. Ask to see the list first.

Alt text describes what the image shows to someone who cannot see it. A filename
is a poor substitute, and a model that has not seen the image is guessing.
Treat what comes back as a draft to review, not an answer.

## Variants

> How many items are in the media library, broken down by MIME type?

> Which uploaded images are wider than 2000px? Those are candidates for resizing.

> Show every PDF in the media library with its title and URL.

`{ "mime_type": "application/pdf" }`.

> Set the caption on image 42 to "Photographed at the 2026 conference".

## Verifying

```bash
./bin/wp post list --post_type=attachment --fields=ID,post_title,post_mime_type
./bin/wp post meta get <ID> _wp_attachment_image_alt
```

## Limits

There is no ability that uploads a file, generates an image, or deletes a media
item. Uploading is a browser, WP-CLI (`wp media import`) or `rest-write` job;
`rest-write` hard-blocks `force=true`, so nothing can be permanently deleted
over MCP in one step.
