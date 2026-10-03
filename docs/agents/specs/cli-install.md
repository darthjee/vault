# CLI Spec: Install

Part of the CLI spec for epic #20. Index: [cli-overview.md](cli-overview.md). Implemented in #26
(`dev`: Dockerfile and `source/bin/install.sh`; `cli`: `install.sh` and `test/install/`).

## What the image ships

| In-image path | Source | Mode |
|---------------|--------|------|
| `/usr/local/bin/vault` | `build/vault` (the bundle) | `0755` |
| `/usr/local/bin/vault-install` | `source/bin/install.sh` | `0755` |
| `/usr/local/share/vault/completion/vault.bash` | `cli/completion/vault.bash` | `0644` |
| `/usr/local/share/vault/completion/_vault` | `cli/completion/_vault` | `0644` |
| `/install` | bind-mount target (not created with content) | — |

- The image's `ENTRYPOINT`, `CMD`, `WORKDIR`, `VOLUME` and `EXPOSE` are unchanged. The default
  behaviour (`docker compose up` from `/vault`) is unchanged.
- The image build needs `build/vault`, so every Make target that builds the image runs
  `bundle-cli` first ([cli-tooling.md](cli-tooling.md#make-targets-and-scripts)).
- A `dev` check (bats or smoke) asserts that the image contains the CLI.

## Install entry (`vault-install`)

```
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --entrypoint vault-install \
  -v "<staging dir>:/install" \
  "$VAULT_IMAGE"
```

- Invoked only through `--entrypoint vault-install`. It takes no arguments.
- It copies, into `/install`:
  - `/install/vault` (mode `0755`);
  - `/install/completion/vault.bash` and `/install/completion/_vault` (mode `0644`).
- It needs **no root, no `--privileged` and no `dockerd`**. It only copies, `mkdir`s and
  `chmod`s; it never starts `dockerd`.
- It runs as the host user (`--user`), so the copied files are owned by that user.
- `/install` missing or not writable → `vault-install: error: /install is not writable`,
  exit 1. Success exits 0 silently.
- It follows the image's library rules (`source/bin/` is an entry point; any helper goes to
  `source/lib/`).

## `install.sh`

Release asset and repo-root script, run as
`curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash`.

### Environment

| Env var | Default | Purpose |
|---------|---------|---------|
| `VAULT_VERSION` | its own stamped version | The version to install. |
| `VAULT_INSTALL_DIR` | `~/.local/bin` | Where `vault` is copied. |
| `VAULT_IMAGE` | `darthjee/vault:$VAULT_VERSION` | The image to install from. The e2e test overrides it with the local build. |

- **Stamped version:** `install.sh` contains the line `VAULT_VERSION="X.Y.Z"`
  ([cli-tooling.md → Version line](cli-tooling.md#version-line)). Because that line assigns the
  variable, `install.sh` saves the caller's `VAULT_VERSION` **before** it, and uses the saved
  value when set, e.g.:

  ```bash
  requested_version="${VAULT_VERSION:-}"
  VAULT_VERSION="0.2.0"
  version="${requested_version:-$VAULT_VERSION}"
  ```

- `VAULT_VERSION=X.Y.Z` pins a version, which means running that image tag.

### Behaviour

1. Checks `docker` is on `PATH` and the daemon is reachable (same messages as the CLI).
2. Resolves the install dir (`VAULT_INSTALL_DIR`, default `$HOME/.local/bin`). It creates it
   when missing; if it cannot be created or is not writable → `error: <dir> is not writable`,
   exit 1, before any `docker run`.
3. Creates a staging dir (`mktemp -d`), and removes it on exit (trap).
4. Runs the install entry (above) with the staging dir on `/install`. The image is pulled by
   `docker run`'s default pull policy (`missing`), so a locally built `VAULT_IMAGE` is used as
   is.
5. Moves `vault` into the install dir (overwriting any previous version, so re-running
   `install.sh` upgrades), and the completions into `$HOME/.local/share/vault/completion/`
   (created when missing).
6. Prints the result and the completion setup lines (stdout).
7. If the install dir is not in `PATH` (exact match against the `:`-separated entries, ignoring
   a trailing `/`), prints the PATH warning. The install still succeeds (exit 0).

- Bash 3.2 compatible, `set -euo pipefail`, shellchecked.
- It writes nothing outside the install dir, the completion dir and the staging dir. It never
  calls `sudo`.
- The pull warms the image cache for running Vault, so pulling the full image to copy one file
  is accepted.
- **Integrity:** the CLI comes from the `darthjee/vault:<version>` image. Tags are not immutable,
  so this relies on Docker Hub's integrity for that tag. The release also ships `SHA256SUMS`
  ([cli-ci.md](cli-ci.md#released-assets)).

## Completion file locations

| Where | bash | zsh |
|-------|------|-----|
| Repo | `cli/completion/vault.bash` | `cli/completion/_vault` |
| Image | `/usr/local/share/vault/completion/vault.bash` | `/usr/local/share/vault/completion/_vault` |
| Host (via `install.sh`) | `~/.local/share/vault/completion/vault.bash` | `~/.local/share/vault/completion/_vault` |
| GitHub release | `vault.bash` | `_vault` |

## Messages

`install.sh` uses the CLI's `vault: ` prefix rules (diagnostics on stderr, normal output on
stdout).

| Case | Stream | Message | Exit |
|------|--------|---------|------|
| docker missing | stderr | `vault: error: docker not found in PATH` | 1 |
| daemon unreachable | stderr | `vault: error: cannot reach the Docker daemon` + `vault: hint: is Docker running, and can this user access it?` | 1 |
| install dir not writable | stderr | `vault: error: <dir> is not writable` | 1 |
| install entry fails | stderr | docker's / `vault-install`'s error, then `vault: error: failed to install from <image>` | 1 |
| installed | stdout | `installed vault <version> to <dir>/vault` | 0 |
| completion setup | stdout | `bash completion: source ~/.local/share/vault/completion/vault.bash` and `zsh completion: add ~/.local/share/vault/completion to fpath` | 0 |
| install dir not in PATH | stderr | `vault: warning: <dir> is not in PATH; add: export PATH="<dir>:$PATH"` | 0 |
| `/install` not writable (entry) | stderr | `vault-install: error: /install is not writable` | 1 |
