# Brand images

`readme-light.svg` and `readme-dark.svg` are the README header sources
(`readme-light.png` / `readme-dark.png`, 2560x1280), switched on GitHub via
`#gh-light-mode-only` / `#gh-dark-mode-only`. `social.svg` is a simplified
light artwork for `social.png` (1280x640, GitHub Settings > Social preview).
`og.svg` → `og.png` (1200x630). All outputs are listed in `brand.config.json`.
Render with
`npx -y -p playwright@1.61.1 -p sharp@0.35.4 node .github/brand/render.mjs`
from the repository root; add `--check` to re-render in memory and exit 1 if
any source or output is stale. Palette tokens live in `tokens.json` (`light`
and `dark`). The fonts are Catamaran, Cabin and Roboto Mono under the
SIL OFL 1.1 (texts in `fonts/`), vendored with `render.mjs`, `embed-fonts.mjs`
and `tokens.json` from the marcopontili.com repo-brand kit; do not edit kit
files here.
