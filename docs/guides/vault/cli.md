# Using the vault CLI

How to install and use the `vault` client, which runs a Vault image on your host for you.
Back to the [Vault guides index](../vault.md).

The `vault` CLI builds the `docker run` command (runtime, mounts, data volume, ports, env) from
a project directory and manages the resulting container:

```bash
cd my-stack            # a directory with a compose file
vault up               # start it, detached, on http://localhost:3000
vault status           # state, image, runtime, ports, volume, env keys
vault compose ps       # run "docker compose ps" inside the instance
vault logs -f          # follow the logs
vault down             # stop and remove it (the data volume is kept)
```

Every command also takes the project directory as an argument (`vault up ./my-stack`);
without it, the current directory is used. Unless said otherwise, examples on this page use
the CLI default port mapping `3000:80` (host `3000` → Vault `80`).

## Supported platforms

| | Supported | Not supported |
|---|-----------|---------------|
| Host OS | Linux and macOS. | Windows. |
| Shell | bash 3.2 or later (the stock macOS bash works). | |
| Docker | A reachable Docker daemon, with Sysbox or accepting `--privileged`. | Rootless Docker (refused by the CLI, whatever the runtime). |

Runtimes, hosts and architectures supported by the image itself are listed in
[security.md → Supported runtimes and platforms](security.md#supported-runtimes-and-platforms).

## Install

Install the CLI with a one-liner:

```bash
curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash
```

The installer needs Docker and never runs `sudo`. It pulls `darthjee/vault:<version>` and
copies the CLI out of that image (its `vault-install` entry, run as the current user, with no
`--privileged` and no inner Docker daemon), so the CLI always matches the image version. By
default it installs:

| What | Where |
|------|-------|
| The `vault` CLI | `~/.local/bin/vault` |
| The shell completions | `~/.local/share/vault/completion/` (`vault.bash`, `_vault`) |

On success it prints `installed vault <version> to <dir>/vault`. Running it again upgrades the
CLI in place.

### Pinning a version

```bash
curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh \
  | VAULT_VERSION=0.0.1 bash
```

### Installer variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `VAULT_VERSION` | the release's version | Version of the CLI (and image) to install. |
| `VAULT_INSTALL_DIR` | `$HOME/.local/bin` | Where the `vault` CLI is installed (created when missing; must be writable). |
| `VAULT_IMAGE` | `darthjee/vault:$VAULT_VERSION` | Image the CLI is copied from. |

These variables only affect the installer: the installed CLI reads none of them. The
completion directory is always `~/.local/share/vault/completion/`.

### PATH

If the install dir is not in `PATH`, the installer warns and prints the line to add; the
install still succeeds:

```
vault: warning: /home/me/.local/bin is not in PATH; add: export PATH="/home/me/.local/bin:$PATH"
```

Add that line to your shell profile (`~/.bashrc`, `~/.zshrc`).

### Installer errors

| Message (stderr) | Cause |
|------------------|-------|
| `vault: error: docker not found in PATH` | Docker is not installed or not in `PATH`. |
| `vault: error: cannot reach the Docker daemon` | The daemon is down, or this user cannot access it. |
| `vault: error: <dir> is not writable` | `VAULT_INSTALL_DIR` cannot be created or written. |
| `vault: error: failed to install from <image>` | The image could not be pulled or run (e.g. unknown `VAULT_VERSION`). |

All of them exit `1`.

## Download and verify

Release tags are not immutable, and `curl | bash` runs whatever the URL serves. Each GitHub
release publishes these assets:

| Asset | Content |
|-------|---------|
| `vault` | The CLI (a single bundled script). |
| `install.sh` | The installer. |
| `vault.bash` | The bash completion. |
| `_vault` | The zsh completion. |
| `SHA256SUMS` | SHA-256 checksums of the four files above. |

To verify the installer before running it:

```bash
base=https://github.com/darthjee/vault/releases/latest/download
curl -fsSLO "$base/install.sh"
curl -fsSLO "$base/SHA256SUMS"
sha256sum -c --ignore-missing SHA256SUMS      # Linux
shasum -a 256 -c --ignore-missing SHA256SUMS  # macOS
bash install.sh
```

The releases are listed on the
[GitHub releases page](https://github.com/darthjee/vault/releases).

## Shell completion

Enable completion in your shell:

```bash
# bash (~/.bashrc)
source ~/.local/share/vault/completion/vault.bash

# zsh (~/.zshrc, before compinit)
fpath=(~/.local/share/vault/completion $fpath)
```

Completion covers the commands, their options, `--runtime` values, files for `--env-file` and
`-v`, directories for `[dir]`, and existing instance names for `--name`.
