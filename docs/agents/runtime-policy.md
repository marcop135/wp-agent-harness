# Runtime policy (sandbox vs autonomous)

Calibrate how much an agent auto-runs vs asks, by risk. This harness is local development only; treat production WordPress targets as out of scope.

## Risk tiers

| Tier | Examples | Agent behaviour |
| --- | --- | --- |
| **Low** | Docs-only (`docs/`, `examples/`, markdown), changelog copy, comments | Prefer read-only checks (`git status`, file reads) without pausing on every step when the tool supports it. |
| **Medium** | Content/site work via MCP or `./bin/wp` (drafts, inspect, patch), `bin/` / `tests/` / Docker image edits on a feature branch, `./bin/setup` / `./bin/status` / `./bin/test --skip-claude` | Work on a feature branch; inspect before change; default to drafts; ask before publish, trash, deactivate, or site-setting changes. |
| **High** | `./bin/reset`, credentials, exposing ports beyond loopback, tracked secrets, destructive git on shared branches, bulk delete of content | Require explicit human confirmation before each step. |

## Ask once per session

The human can set:

- **Mode A (Tight):** default; approvals for most shell/network.
- **Mode B (Balanced):** allowlist `./bin/status`, `./bin/wp`, `./bin/test --skip-claude`, `git diff` / `status` / `log` for this repo.
- **Mode C (Fast loop, local only):** broader auto-run only on a **disposable** branch with no secrets in the working tree, still no `./bin/reset` without an explicit ask.

Cloud agents should assume **Mode A** unless the user states otherwise.

## When broad auto-run is inappropriate

- Committing or pushing directly to `main`.
- Writing credentials into tracked files, logs, or image layers.
- Skipping `CHANGELOG.md` when changing behaviour agents or contributors rely on.
- Calling `./bin/reset` or publishing/deleting content without an explicit instruction.

## Evidence before “done”

Run the verification you claim (`./bin/test --skip-claude`, MCP execute, or `./bin/wp ability …`); do not assume success.
