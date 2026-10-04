# Issue: Guides: using the vault CLI

## Description
Part of epic #39 (portable user guides for Vault). Writes `docs/guides/vault/cli.md`, the
guide to the `vault` client (built in epic #20), following
[guides-pages.md → cli.md](../specs/guides-pages.md#climd). Depends on #42 (index, concepts and
security). Can run in parallel with #43 and #45. Agent: `product-owner`.

## Problem
Consumer repos need a guide to the `vault` client that still works once the `docs/guides/`
tree is copied into their repo. Today `vault.md`, `docker-run.md` and `base-image.md` name
`cli.md` as "not written yet".

## Expected Behavior
`docs/guides/vault/cli.md` exists, starts with the standard page header (one-line purpose and a
link back to `../vault.md`), and covers:
- **Install:** the `curl -fsSL .../install.sh | bash` one-liner (absolute URL), pinning
  `VAULT_VERSION`, `VAULT_INSTALL_DIR` and the other installer variables, `PATH`, download
  and integrity check (`SHA256SUMS`).
- **Commands:** `up` (detached, `-f`), `down`, `logs [-f]`, `status`, `compose <args>`,
  `run <args>`, `version`, `help`; exit codes and message prefixes.
- **Instance naming:** `vault-<name>`, `vault-<name>-data`, `--name`, and the shared-volume
  warning.
- **Runtime selection:** `--runtime auto|sysbox|privileged` and the `--privileged` fallback
  warning (link to `security.md`).
- **Options:** ports (default `3000:80`), volumes, env, env files, stop timeout, `--image` for
  baked images (link to `base-image.md`).
- **`.vaultrc` and `.vault.env`:** keys, precedence (flags > `.vaultrc` > defaults), relative
  paths, keeping `.vault.env` out of git. The `.vaultrc` section has its own heading so the
  `cli.md#vaultrc` anchor used in the portability spec resolves. Detailed secrets handling stays
  in `configuration.md` (#45), named in inline code until it lands.
- **Guardrails** enforced by the CLI.
- **Shell completion:** bash and zsh.
- **Supported platforms:** Linux and macOS, bash 3.2+; Windows not supported; Docker Desktop
  file-sharing paths.

Cross-references:
- `vault.md` links `vault/cli.md` in the "Choosing a path" table and adds it to the page index.
- The "`cli.md` (not written yet)" mentions in `docker-run.md` and `base-image.md` become
  real links.

All links follow the portability rules, the version line stays correct, and `make test-docs`
passes. Content matches the CLI's actual behaviour and messages (checked against `cli/` and the
README's CLI section).
