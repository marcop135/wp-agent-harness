# Examples

Prompts that work against this site, with the abilities each one uses and what
you should see. Each example has the same shape: prompt, abilities, expected
result, a `./bin/wp` check, follow-ups.

```bash
./bin/start
./bin/seed                    # demo content the examples use (./bin/seed --remove deletes it)
./bin/connect                 # Claude Code
# or: eval "$(./bin/connect --print | grep '^export ')"   # Codex / Cursor
claude                        # or: codex
./bin/audit                   # the writes agents made
```

| Example | Covers | Writes |
|---------|--------|--------|
| [inspect-site.md](inspect-site.md) | Version, theme, plugins, post types, content | None |
| [create-content.md](create-content.md) | A draft page in native blocks | Draft, gate asks |
| [modify-content.md](modify-content.md) | Restructuring the seeded Wholesale draft, diff first | Gate asks |
| [theme.md](theme.md) | Twenty Twenty-Five's templates, parts and patterns | None |
| [media.md](media.md) | Seeded images missing alt text, and fixing them | Gate asks |
| [plugins.md](plugins.md) | Installed plugins, state, available updates | None |
| [site-development.md](site-development.md) | A Services section on the existing architecture | Drafts, gate asks |

Reads (`get-*`, `rest-get`, `preview-post-update`, `core/get-*`) run freely.
Every other ability changes the site; in Claude Code and Cursor the approval
gate asks before each call, naming the ability
([docs/security.md](../docs/security.md#the-approval-gate)).

Each prompt takes several tool calls: a discovery or schema lookup, then the
work ([docs/architecture.md](../docs/architecture.md#why-three-tools-and-not-thirty)).
The pinned MS WP Abilities release defines the real set:

```bash
./bin/wp ability list --namespace=miriamschwab --fields=name,label
```

## End-to-end demonstration

[create-content.md](create-content.md) ends with a create, read, modify, verify
and trash walkthrough on a page called **MCP Integration Test**. The automated
version drives a headless Claude Code session, checks every step with WP-CLI,
then removes the page:

```bash
./bin/test claude-code
```
