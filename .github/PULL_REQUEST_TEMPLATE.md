# What this changes

<!-- One paragraph. What is different after this merges, and why. -->

Closes #

## Type

- [ ] Fix
- [ ] Feature
- [ ] Documentation
- [ ] Version pin
- [ ] CI or tests

## What was run

<!-- Paste the result lines, not the whole output. -->

- [ ] `./bin/test --skip-claude` (layers 0-3)
- [ ] `./bin/test claude-code` (layer 4, costs model turns)
- [ ] `./bin/reset --yes && ./bin/test --skip-claude` (clean build)
- [ ] `shellcheck bin/* tests/*.sh`

## Checklist

- [ ] `./bin/setup` is still idempotent and still destroys nothing.
- [ ] No credential reaches a tracked file, a log or a build layer.
- [ ] Ports still bind to `127.0.0.1`.
- [ ] A changed version pin is in both `.env` and `.env.example`, with the
      upstream release named in the description.
- [ ] Documentation changed by replacing, not appending: each topic still has
      one home.
