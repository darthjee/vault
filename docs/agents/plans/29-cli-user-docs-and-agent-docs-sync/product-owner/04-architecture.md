# architecture.md

- **Image paths table:** add `/usr/local/bin/vault` (the bundled CLI), `/usr/local/bin/vault-install`
  (install entry, `source/bin/install.sh`) and `/usr/local/share/vault/completion/`
  (`vault.bash`, `_vault`). Match the `Dockerfile`.
- **Source Code Layout:** `source/bin/` now has two entry points (`entrypoint.sh`,
  `install.sh`); add `source/lib/install.sh` to the libraries table.
- **New `## CLI` section:** layout (`cli/bin/vault` is the only file that reads `.vaultrc` and
  the environment; libraries only define functions and take values as arguments), library
  table (responsibility per `cli/lib/*.sh`), bundling rule (`scripts/bundle_cli.sh`, fixed
  order, self-contained `build/vault`), bash 3.2 constraints (no associative arrays, no
  `mapfile`, no `${var,,}`), message prefixes (`vault: error:` / `warning:` / `hint:`) and exit
  codes (0 / 1 / 2, passthrough of docker/compose codes), completion files.
- **Installer:** `install.sh` (environment, staging dir, `vault-install`, completions, PATH
  warning), and the GitHub release assets.
- **Testing table:** `make test` now also covers `test/cli/`, `test/install/` and
  `test/scripts/` on `BATS_IMAGE`, `test/cli/` + `test/install/` on bash 3.2
  (`test/bash32/`), and `zsh -n` on `_vault`; `make lint` covers `cli/` and `install.sh`.
  Keep the existing end-to-end row.

## Files to Change
- `docs/agents/architecture.md` — image paths, source layout, new CLI and installer
  sections, testing table.
