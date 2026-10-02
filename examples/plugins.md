# Plugins and updates

Inspection is read-only. Installing, activating and updating are not — see the
warning at the bottom.

## Prompt

> Inspect the installed plugins and report their active/inactive state and
> available updates. Do not change anything.

## Abilities used

| Ability | For |
|---------|-----|
| `miriamschwab/get-plugins` | name, version, active state, update availability |
| `miriamschwab/get-available-updates` | pending plugin, theme and core updates |
| `miriamschwab/get-themes` | the same for themes |

`get-plugins` takes an optional `status` of `all` (default), `active` or
`inactive`.

## What you should see

Exactly two plugins, both active:

```
mcp-adapter/mcp-adapter.php        MCP Adapter               0.7.0   active
ms-wp-abilities/ms-wp-abilities.php  MS WordPress Abilities  1.12.0  active
```

Provisioning removes the Akismet and Hello Dolly that the base image ships, so
this site's plugin set is only what the toolkit needs.

`get-available-updates` reads WordPress's cached update data. On a fresh install
that cache may be empty until WordPress runs its update check; an empty result
means "nothing known yet", not "nothing available". Force a refresh:

```bash
./bin/wp plugin list --fields=name,version,update,update_version
./bin/wp core check-update
```

Note that MCP Adapter and MS WP Abilities are installed from GitHub release ZIPs,
not from wordpress.org, so WordPress's update checker has nothing to compare
them against and will never report an update for them. Version bumps go through
`.env` — see
[docs/development.md](../docs/development.md#updating-dependencies).

## Variants

> Which plugins are installed but inactive?

> Is there a WordPress core update available, and what version would it go to?

> For each active plugin, tell me its REST API namespace if it registers one.

That last one uses `rest-get` against `/` or a guessed namespace, which is how
Claude finds out what a third-party plugin can actually do.

## Writing

Three abilities change plugin state:

| Ability | Input |
|---------|-------|
| `miriamschwab/install-plugin` | a **wordpress.org slug**, plus optional `activate: true` |
| `miriamschwab/activate-plugin` | a plugin file path, e.g. `woocommerce/woocommerce.php` |
| `miriamschwab/update-plugin` | a plugin file path |

**Installing and activating a plugin is arbitrary code execution inside the
WordPress container.** Nothing in the chain vets what wordpress.org serves. Only
ask for this when you mean it, and read
[docs/security.md](../docs/security.md).

A plugin installed this way is not in `.env`, so `./bin/reset` will not bring it
back. Anything you want to survive a reset belongs in the provisioning script.

Deactivation and deletion are deliberately absent: there is no deactivate or
delete ability, and `rest-write` hard-blocks `DELETE` on `/wp/v2/plugins`. Use
WP-CLI:

```bash
./bin/wp plugin deactivate <slug>
./bin/wp plugin delete <slug>
```

## Verifying

```bash
./bin/wp plugin list --fields=name,status,version,update
./bin/wp plugin status
./bin/wp theme list
```
