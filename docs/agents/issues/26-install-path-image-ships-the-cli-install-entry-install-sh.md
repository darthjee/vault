# Issue: Install path: image ships the CLI, install entry, install.sh

## Description
Part of epic #20 (Vault CLI). Depends on #22 (scaffolding/tooling), #23 (CLI core) and #24 (CLI commands), all merged.

Ship the CLI inside the Vault image and give users a `curl | bash` installer that copies it out of the image of the matching version. The source of truth is [`docs/agents/specs/cli-install.md`](../specs/cli-install.md) (plus `cli-tooling.md` for the Make/version wiring).

Agents:
- `dev`: `Dockerfile`, `source/bin/install.sh` (installed as `vault-install`), and the image check that the CLI is present;
- `cli`: root `install.sh` and `test/install/*.bats`;
- `automation`: Makefile wiring (`bundle-cli` before every image build) and making `install.sh` required in the version scripts;
- `architect`: the README install section (root-level file).

## Problem
Users have no way to get the CLI onto their host. The epic decided that the CLI comes from the image of the same version, so the CLI and the image stay in lock-step. Today the image does not contain the CLI, there is no install entry, and there is no `install.sh`.

## Expected Behavior
### Image (`dev`)
- The `Dockerfile` copies:
  - `build/vault` → `/usr/local/bin/vault` (`0755`);
  - `source/bin/install.sh` → `/usr/local/bin/vault-install` (`0755`);
  - `cli/completion/vault.bash` and `cli/completion/_vault` → `/usr/local/share/vault/completion/` (`0644`).
- `ENTRYPOINT`, `CMD`, `WORKDIR`, `VOLUME` and `EXPOSE` are unchanged; the default behaviour (`docker compose up` from `/vault`) is unchanged.
- A `dev` check (bats or smoke) asserts that the image contains the CLI.

### Install entry `vault-install` (`dev`)
- Invoked only through `--entrypoint vault-install`; takes no arguments.
- Copies into the bind-mounted `/install`: `/install/vault` (`0755`), `/install/completion/vault.bash` and `/install/completion/_vault` (`0644`).
- Needs no root, no `--privileged`, no `dockerd`: it only copies, `mkdir`s and `chmod`s.
- `/install` missing or not writable → `vault-install: error: /install is not writable`, exit 1. Success exits 0 silently.
- Follows the image library rules (any helper goes to `source/lib/`).

### `install.sh` at the repo root (`cli`)
- Run as `curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash`.
- Env: `VAULT_VERSION` (default: its own stamped `VAULT_VERSION="X.Y.Z"` line; the caller value is saved **before** that line), `VAULT_INSTALL_DIR` (default `$HOME/.local/bin`), `VAULT_IMAGE` (default `darthjee/vault:$VAULT_VERSION`).
- Behaviour:
  1. Checks `docker` is on `PATH` and the daemon is reachable (same messages as the CLI).
  2. Resolves the install dir, creating it when missing; not creatable / not writable → `vault: error: <dir> is not writable`, exit 1, before any `docker run`.
  3. Creates a staging dir (`mktemp -d`), removed on exit (trap).
  4. Runs `docker run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install -v "<staging>:/install" "$VAULT_IMAGE"` (default pull policy, so a locally built image is used as is). On failure → `vault: error: failed to install from <image>`, exit 1.
  5. Moves `vault` into the install dir (overwrites, so re-running upgrades) and the completions into `$HOME/.local/share/vault/completion/` (created when missing).
  6. Prints `installed vault <version> to <dir>/vault` and the bash/zsh completion setup lines (stdout).
  7. If the install dir is not in `PATH` (exact match, ignoring a trailing `/`): `vault: warning: <dir> is not in PATH; add: export PATH="<dir>:$PATH"` on stderr, still exit 0.
- Bash 3.2 compatible, `set -euo pipefail`, shellchecked; never calls `sudo`; writes nothing outside the install dir, the completion dir and the staging dir.

### Tooling (`automation`)
- Every Make target that builds the image (`build-image`, so `test-image`; `release`) runs `bundle-cli` first.
- `scripts/bump_version.sh` and `scripts/check_tag_version.sh` treat `install.sh` as **required** (exactly one `VAULT_VERSION` line), no longer "when it exists".

### Docs (`architect`)
- `README.md` gains an **Install** section: the `curl | bash` one-liner, the `VAULT_VERSION` / `VAULT_INSTALL_DIR` / `VAULT_IMAGE` overrides, the completion setup lines and the PATH note.

### Tests
- bats under `test/install/` for `install.sh` with a stub `docker`: env vars and defaults, version override, not-writable dir, missing dir creation, entry failure, PATH warning, completion placement. They run on both `BATS_IMAGE` and bash 3.2.
- The `dev` image check above.
- `make lint`, `make test` and `make test-image` pass.

### Out of scope
- `make test-cli-e2e` (#27) and the GitHub release assets (#28).

## Solution
Follow `docs/agents/specs/cli-install.md`. Install via a staging dir rather than bind-mounting the target dir directly, so the target dir is checked for writability before any `docker run`, the completions can go to a separate host dir, and a failed run leaves the existing install untouched.

## Benefits
- One-line install with no `sudo`, with files owned by the host user.
- The installed CLI always matches the image version it drives.
