# README CLI section

Restructure `README.md` around a new top-level `## CLI` section, placed where `## Install` is
today (before `## Usage`). Move the current `## Install` content under it as `### Install`
(`####` for its subsections), and drop the two "(#28)" placeholders: the release assets exist.

Subsections of `## CLI`:

1. **Intro + quick start:** what the CLI does (builds the `docker run` for you), then
   `vault up` / `vault status` / `vault compose ps` / `vault logs -f` / `vault down` on a
   project directory. Supported platforms: Linux and macOS (bash 3.2+, stock macOS bash works);
   not Windows.
2. **Install** (moved): one-liner, what it installs, installer variables (`VAULT_VERSION`,
   `VAULT_INSTALL_DIR`, `VAULT_IMAGE`), pinning, completion and `PATH`, upgrade by re-running.
   Add the download-and-verify alternative: download `install.sh` and `SHA256SUMS` from the
   release, `sha256sum -c --ignore-missing` (or `shasum -a 256 -c` on macOS), then
   `bash install.sh`. Mention the release assets (`vault`, `install.sh`, `vault.bash`, `_vault`,
   `SHA256SUMS`). Note the install step runs the image's `vault-install` entry (no root, no
   `--privileged`), and that it is not a `vault` subcommand.
3. **Commands:** table of `up`, `down`, `logs`, `status`, `compose`, `run`, `version`, `help`
   (from `cli-commands.md → Commands`), including: `up` is detached unless `-f`/`--attach`,
   already running → no-op; `down` keeps the data volume; `run` refuses while the instance is
   running; `run` vs `[dir]` (first positional is `[dir]` only if it is an existing
   directory; `--` ends options).
4. **Instances:** the name (`--name`, else `.vaultrc`, else image name with `--image` and no
   `[dir]`, else directory basename, sanitized), container `vault-<name>`, volume
   `vault-<name>-data` on `/var/lib/docker`. **Warning:** two instances must not share a data
   volume (e.g. two directories with the same basename) — pass `--name`.
5. **Runtime:** `--runtime auto|sysbox|privileged` table (auto → Sysbox if detected, else
   `--privileged` with a warning; `sysbox` without Sysbox fails; `privileged` is silent).
   Rootless Docker is refused. A failed Sysbox run never falls back. Link to
   [Security](#security).
6. **Options and configuration:** options table (`--name`, `--image`, `--runtime`, `-p`
   default `3000:80`, `-v`, `-e`, `--env-file`, `--stop-timeout` default 60, `-f`); env vars
   for the container (`COMPOSE_UP_ARGS`, `VAULT_DOCKERD_TIMEOUT`, `COMPOSE_*`) via `-e` /
   env files; `.vault.env` (auto-loaded from `[dir]`, else `$PWD`); `.vaultrc` (format
   example, keys, never sourced, relative paths resolved against its directory, precedence
   flags > `.vaultrc` > defaults, a repeatable flag replaces all `.vaultrc` entries of that
   key); guardrails (host `docker.sock` mounts and container ports 2375/2376 are refused).
7. **Baked images:** `vault up --image my-app` with no `[dir]` runs a derived image without
   mounting `/vault`; link to [Shipping a stack as its own image](#shipping-a-stack-as-its-own-image).
8. **Docker Desktop:** `[dir]` and `-v` sources must be in Docker Desktop's shared file paths
   (documented, not checked).
9. **Completion:** bash and zsh (already in Install; keep one place, link from here or move).

Check `.vaultrc` keys, messages and defaults against `cli/lib/*.sh` and
`docs/agents/specs/cli-config.md` / `cli-commands.md`. Update `## Development` with the CLI
targets (`make bundle-cli`, `make test-cli-e2e`) and note that `make test` also runs the CLI
tests under bash 3.2. Keep `**Current Version:**` untouched.

## Files to Change
- `README.md` — new `## CLI` section (absorbing `## Install`), Development targets.
