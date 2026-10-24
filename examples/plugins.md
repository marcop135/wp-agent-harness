# Plugins and updates

The report is read-only. Installing, activating and updating write, and the
approval gate asks.

> Report installed plugins, which are active, and available updates. Do not
> change anything.

| Ability | Used for | Type |
|---------|----------|------|
| `get-plugins` | name, version, active state, update availability; optional `status`: `all` (default), `active`, `inactive` | read |
| `get-available-updates` | pending plugin, theme and core updates, from cached data | read |
| `get-themes` | the same for themes | read |
| `install-plugin` | a **wordpress.org slug**, plus optional `activate: true` | write, gate asks |
| `activate-plugin` | a plugin file path, e.g. `woocommerce/woocommerce.php` | write, gate asks |
| `update-plugin` | a plugin file path | write, gate asks |

## What you should see

```
mcp-adapter/mcp-adapter.php          MCP Adapter             0.7.1   active
ms-wp-abilities/ms-wp-abilities.php  MS WordPress Abilities  1.13.0  active
```

- Only these two: provisioning removes the base image's Akismet and Hello Dolly
- No updates for either: both install from GitHub release ZIPs, so WordPress has
  nothing to compare them against. Version bumps go through `.env`
  ([docs/development.md](../docs/development.md#updating-dependencies)).
- An empty `get-available-updates` on a fresh install means "nothing known yet",
  not "nothing available", until WordPress runs its update check

## Verify

```bash
./bin/wp plugin list --fields=name,status,version,update,update_version
./bin/wp core check-update
./bin/wp theme list
```

## Follow-ups

> Which plugins are installed but inactive?

> Is there a WordPress core update available, and what version would it go to?

> For each active plugin, tell me its REST API namespace if it registers one.

The last uses `rest-get` against `/` or a guessed namespace.

## Writing plugins

**Installing and activating a plugin is arbitrary code execution inside the
WordPress container.** Nothing in the chain vets what wordpress.org serves. Read
[docs/security.md](../docs/security.md) first.

- A plugin installed this way is not in `.env`, so `./bin/reset` will not bring
  it back. What should survive a reset belongs in the provisioning script.
- There is no deactivate or delete ability, and `rest-write` hard-blocks
  `DELETE` on `/wp/v2/plugins`. Use WP-CLI:

```bash
./bin/wp plugin deactivate <slug>
./bin/wp plugin delete <slug>
```
