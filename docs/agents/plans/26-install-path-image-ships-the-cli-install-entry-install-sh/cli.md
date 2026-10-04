# Cli Plan: Install path: image ships the CLI, install entry, install.sh

Main plan: [plan.md](plan.md)

## Shared contracts

- **Relies on** the `vault-install` contract from [plan.md](plan.md#shared-contracts): the
  staging dir ends up holding `vault` and `completion/{vault.bash,_vault}`.
- **Produces** the `install.sh` surface (version line, env vars, messages) that `automation`'s
  version scripts and `architect`'s README rely on.

## Implementation Steps

### Step 1 — Root `install.sh`
Write `install.sh` at the repo root, following [cli-install.md → install.sh](../../specs/cli-install.md#installsh).
It is fetched with `curl | bash`, so it must be **self-contained**: it cannot source `cli/lib/`.
Define small local helpers that match `cli/lib/output.sh` (`vault: <level>: <msg>` on stderr).

- `#!/usr/bin/env bash`, `set -euo pipefail`, bash 3.2 compatible (no `mapfile`, no
  associative arrays, no `${x,,}`), shellcheck-clean.
- Version handling, in this order:
  `requested_version="${VAULT_VERSION:-}"`, then exactly one column-0 line `VAULT_VERSION="0.0.1"`,
  then `version="${requested_version:-$VAULT_VERSION}"`.
  `image="${VAULT_IMAGE:-darthjee/vault:$version}"`,
  `install_dir="${VAULT_INSTALL_DIR:-$HOME/.local/bin}"`, and the completion dir
  `$HOME/.local/share/vault/completion`.
- Flow, wrapped in a `main` function called on the last line, so a truncated download runs nothing:
  1. `command -v docker`, or `vault: error: docker not found in PATH` (exit 1). `docker info`
     (output discarded), or `vault: error: cannot reach the Docker daemon` +
     `vault: hint: is Docker running, and can this user access it?` (exit 1).
  2. `mkdir -p "$install_dir"` (errors silenced). If it is not a writable dir:
     `vault: error: <dir> is not writable`, exit 1. This happens **before** any `docker run`.
  3. `staging="$(mktemp -d)"`, with `trap 'rm -rf "$staging"' EXIT`.
  4. `docker run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install -v "$staging:/install" "$image"`.
     On failure, docker's stderr passes through, then `vault: error: failed to install from <image>`, exit 1.
  5. Move `$staging/vault` into `$install_dir/vault` (overwrite). `mkdir -p` the completion dir
     and move both completion files into it.
  6. stdout: `installed vault <version> to <dir>/vault`, then
     `bash completion: source ~/.local/share/vault/completion/vault.bash` and
     `zsh completion: add ~/.local/share/vault/completion to fpath`.
  7. PATH check: exact match of `$install_dir` (trailing `/` stripped) against each
     `:`-separated `PATH` entry (also stripped). If there is no match:
     `vault: warning: <dir> is not in PATH; add: export PATH="<dir>:$PATH"`, where
     `$PATH` is printed literally. Still exit 0.
- Never `sudo`. Write nothing outside the install dir, the completion dir and the staging dir.

Mark it executable (`git update-index --chmod=+x` / mode 0755). `scripts/lint.sh` already lints it by path.

### Step 2 — `test/install/` bats suite
Add `test/install/install.bats`. It is picked up automatically by `scripts/test.sh` on both
`BATS_IMAGE` and bash 3.2. Reuse the stub docker with `load ../cli/helpers/docker_stub`, and set
`HOME` to a temp dir. Add a stub `docker run` that writes the staged files into the `-v` source
dir: parse the `<dir>:/install` argument from the call, or script it with a small helper in
`test/install/helpers/`. Cover:
- the defaults: image `darthjee/vault:<VERSION>` (read from `VERSION`), the install dir `$HOME/.local/bin`, the completion dir; the exact `docker run` argument list, including `--user <uid>:<gid>`, `--entrypoint vault-install` and `-v <staging>:/install`;
- `VAULT_VERSION=9.9.9` → image `darthjee/vault:9.9.9` and the version shown in the "installed" line;
- `VAULT_IMAGE` override; `VAULT_INSTALL_DIR` override;
- a missing install dir is created;
- an install dir that is not writable → exact error, exit 1, and **no** `docker run` call (skip when running as root);
- the docker binary missing from PATH; `docker info` failing → error + hint;
- `docker run` failing → `failed to install from <image>`, exit 1, and the install dir left untouched;
- the install dir not in PATH → the warning on stderr, exit 0. In PATH, with and without a trailing `/` → no warning;
- re-running overwrites an existing `vault`; the staging dir is removed afterwards;
- the stdout lines, exactly.

## Files to Change
- `install.sh` — new curl|bash installer (mode 0755).
- `test/install/install.bats` — new tests.
- `test/install/helpers/*.bash` — optional helper for the staging-aware `docker run` stub.

## CI Checks
- `install.sh`, `test/install/`: `make lint`, `make test` (CI job: `build-and-test`)

## Notes
- `.gitignore` lists `docker_stub.bash` / `vault_cli.bash` by basename. A new helper in
  `test/install/helpers/` with a different name is not affected. If one ever shares those names,
  it needs `git add -f`.
- Once `install.sh` exists, `make check-version-tag` checks it. Keep its line equal to `VERSION`.
