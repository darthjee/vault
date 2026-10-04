# Plan: Install path: image ships the CLI, install entry, install.sh

Issue: [26-install-path-image-ships-the-cli-install-entry-install-sh.md](../../issues/26-install-path-image-ships-the-cli-install-entry-install-sh.md)

## Overview
The Vault image starts shipping the bundled CLI (`build/vault`), an in-image install entry
(`vault-install`) and the shell completions. A new root `install.sh` (`curl | bash`) pulls
`darthjee/vault:<version>` and runs `vault-install` as the host user against a staging dir, then
moves the CLI into `~/.local/bin` and the completions into `~/.local/share/vault/completion/`.
The Make targets that build the image run `bundle-cli` first, the version scripts make
`install.sh` required, and the README documents the install. The source of truth is
`docs/agents/specs/cli-install.md` (plus `cli-tooling.md` for the version and Make rules).

## Agents involved

- [dev](dev.md): `Dockerfile`, `source/bin/install.sh`, `source/lib/install.sh`, `test/lib/install.bats`
- [cli](cli.md): `install.sh`, `test/install/*.bats`
- [automation](automation.md): `Makefile`, `scripts/bump_version.sh`, `scripts/check_tag_version.sh`, `scripts/test_image.sh`
- [architect](architect.md): `README.md`

`dev` and `cli` can work in parallel. `automation`'s Makefile step must land with `dev`'s
Dockerfile change, because the image build needs `build/vault`. Its image check relies on
`dev`'s in-image paths. `architect` documents `cli`'s env vars and messages.

## Shared contracts

### In-image paths (produced by `dev`; consumed by `cli`, `automation`)

| In-image path | Source | Mode |
|---------------|--------|------|
| `/usr/local/bin/vault` | `build/vault` | `0755` |
| `/usr/local/bin/vault-install` | `source/bin/install.sh` | `0755` |
| `/usr/local/share/vault/completion/vault.bash` | `cli/completion/vault.bash` | `0644` |
| `/usr/local/share/vault/completion/_vault` | `cli/completion/_vault` | `0644` |

`ENTRYPOINT`, `CMD`, `WORKDIR`, `VOLUME` and `EXPOSE` are unchanged.

### `vault-install` invocation (produced by `dev`; consumed by `cli`, `automation`)

```
docker run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install -v "<staging dir>:/install" "$VAULT_IMAGE"
```

- No arguments. No root, no `--privileged`, no `dockerd`.
- Writes `/install/vault` (`0755`), `/install/completion/vault.bash` and `/install/completion/_vault` (`0644`).
- `/install` missing or not writable → stderr `vault-install: error: /install is not writable`, exit 1.
- Success: exit 0, no output.

### Build prerequisite (produced by `automation`; consumed by `dev`)
- `build/vault` must exist in the build context before `docker build`. `build-image` (and so
  `test-image`) and `release` depend on `bundle-cli`. `.dockerignore` must not exclude `build/`.

### `install.sh` surface (produced by `cli`; consumed by `automation`, `architect`)
- Exactly one column-0 line `VAULT_VERSION="X.Y.Z"`, stamped from `VERSION` (currently `0.0.1`),
  matching `^VAULT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$`.
- Env: `VAULT_VERSION` (default: stamped), `VAULT_INSTALL_DIR` (default `$HOME/.local/bin`),
  `VAULT_IMAGE` (default `darthjee/vault:$VAULT_VERSION`).
- Messages, exactly as in [cli-install.md → Messages](../../specs/cli-install.md#messages).
