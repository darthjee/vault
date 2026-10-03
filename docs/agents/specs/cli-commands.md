# CLI Spec: Commands

Part of the CLI spec for epic #20. Index: [cli-overview.md](cli-overview.md).

## Syntax

```
vault <command> [options] [dir] [args]
```

- Long options take their value as `--opt value` or `--opt=value`; short options as `-x value`.
- `up`, `down`, `logs`, `status`: options and `[dir]` may appear in any order.
- `compose`, `run`: option parsing stops at the first argument that is not a CLI option (for
  `run`, after the optional `[dir]`); that argument and everything after it are passed verbatim
  to compose. `--` ends option parsing explicitly.
- `run` and `[dir]` (decided by #23, open point 1): the first positional argument is `[dir]`
  only when it names an existing directory; otherwise it is the first compose argument
  (`vault run config` passes `config` to the entrypoint). To pass an argument that happens to
  name an existing directory, put `--` before it.
- `vault` with no command prints the usage to stderr and exits 2.

## Commands

| Command | Behaviour |
|---------|-----------|
| `vault up [options] [dir]` | `docker run -d` of the image as `vault-<name>`. Detached by default; `-f` / `--attach` runs it in the foreground, where Ctrl+C triggers the image's graceful shutdown. Already running → no-op. Exists but stopped → `docker rm`, then a fresh `docker run` with the current flags. |
| `vault down [options]` | `docker stop -t <stop-timeout>`, then `docker rm` of `vault-<name>`. The data volume is never removed. A missing instance exits 0. |
| `vault logs [options] [-f]` | `docker logs [-f] vault-<name>`. Fails when the instance is not running. |
| `vault status [options]` | Reports the instance (see [status output](#status-output)). A missing or stopped instance is reported, not a failure (exit 0). |
| `vault compose [options] <args>` | `docker exec vault-<name> docker compose <args>`. Fails when the instance is not running. |
| `vault run [options] [dir] <args>` | One-shot `docker run --rm` (foreground) that passes `<args>` to the image's entrypoint, e.g. `vault run config`. No long-running instance. |
| `vault version` | Prints `vault X.Y.Z` (the `VAULT_VERSION` line) to stdout, exit 0. |
| `vault help` | Prints the usage to stdout, exit 0. `-h` / `--help` on any command does the same. |

- `vault install` (listed in epic #20) is **not** a CLI command: the install step is the
  separate in-image entry `vault-install` ([cli-install.md](cli-install.md)).
- `up` and `run` build the same container arguments (runtime, mounts, ports, env, stop
  timeout). `run` adds `--rm`, has no `--name`, and never uses `-d`.

### Container arguments (`up`, `run`)

In this order:

1. The runtime: `--runtime=sysbox-runc` or `--privileged` ([runtime selection](#runtime-selection)).
2. `--stop-timeout <stop-timeout>`.
3. `-v <dir>:/vault`, unless `--image` was given without an explicit `[dir]`.
4. `-v vault-<name>-data:/var/lib/docker` (always).
5. Each extra `-v SRC:DST`, in order.
6. Each `-p HOST:CONTAINER`, in order (default `3000:80`).
7. `--env-file <dir>/.vault.env` when it exists, then each `--env-file`, then each `-e KEY=VALUE`.
8. `up` only: `--name vault-<name>` and `-d` (unless `-f`).
9. The image, then (`run` only) the compose args.

The exact argument order may be refined by #23 / #24, but tests assert the full list.

## Options

| Option | Commands | Default | Meaning |
|--------|----------|---------|---------|
| `--name <name>` | `up`, `down`, `logs`, `status`, `compose`, `run` | see [instance naming](#instance-naming) | Instance name. |
| `--image <image>` | all of the above | `darthjee/vault:<VAULT_VERSION>` | Image to run. On `down`/`logs`/`status`/`compose` it only feeds the name default. |
| `--runtime <auto\|sysbox\|privileged>` | `up`, `run` | `auto` | Runtime selection. |
| `-p`, `--port <HOST:CONTAINER>` | `up`, `run` | `3000:80` | Published port; repeatable. |
| `-v`, `--volume <SRC:DST>` | `up`, `run` | none | Extra mount; repeatable. |
| `-e`, `--env <KEY=VALUE>` | `up`, `run` | none | Env var; repeatable. |
| `--env-file <file>` | `up`, `run` | none | Env file; repeatable. |
| `--stop-timeout <seconds>` | `up`, `run`, `down` | `60` | Positive integer. |
| `-f`, `--attach` | `up` | off | Run in the foreground. |
| `-f`, `--follow` | `logs` | off | Follow the logs. |

- Every option except `-f` can also come from `.vaultrc` ([cli-config.md](cli-config.md)).
- Precedence: flags > `.vaultrc` > built-in defaults. For the repeatable `-p`, `-v` and `-e`,
  any flag replaces every `.vaultrc` entry of that key.
- Env vars the user may want to set on the Vault container: `COMPOSE_UP_ARGS`,
  `VAULT_DOCKERD_TIMEOUT`, `COMPOSE_FILE`, `COMPOSE_PROJECT_NAME`, … (passed with `-e` / env
  files; the CLI does not interpret them).

## Instance naming

1. `--name`, else `name=` in `.vaultrc`.
2. Else, when `--image` was given and no `[dir]`: the image name without registry, path and
   tag/digest (`registry.example.com/team/my-app:1.0` → `my-app`).
3. Else, the basename of `[dir]` (else `$PWD`).

- **Sanitizing** (derived names, 2 and 3): lowercase, then delete every character outside
  `[a-z0-9_.-]` (`My App!` → `myapp`).
- **Explicit names** (`--name`, `name=`) are validated, not altered: they must match
  `[a-z0-9][a-z0-9_.-]*`, otherwise "bad option value" (exit 2) or "`.vaultrc` bad value"
  (exit 1).
- An empty sanitized result fails: `error: cannot derive an instance name from '<base>'` + hint
  `pass --name <name>` (exit 2).
- The name gives the container `vault-<name>` and the volume `vault-<name>-data`.
- `image=` in `.vaultrc` changes the image only: it does not change the name default nor the
  `/vault` mount.
- `.vaultrc` is read from `[dir]`, else `$PWD`.
- Two names that end up sharing a data volume are not detected; the README documents it (as
  for the image's shared `/var/lib/docker` warning).

## Runtime selection

Applies to `up` and `run` only.

| `--runtime` | Sysbox detected | Result |
|-------------|-----------------|--------|
| `auto` | yes | `--runtime=sysbox-runc`, no message. |
| `auto` | no | `--privileged`, with the fallback **warning**. |
| `sysbox` | yes | `--runtime=sysbox-runc`. |
| `sysbox` | no | Error, exit 1. No fallback. |
| `privileged` | either | `--privileged`, no warning (an informed choice). |

- **Detection:** `docker info` lists `sysbox-runc` in `{{json .Runtimes}}`.
- **Rootless:** `docker info` security options contain `rootless` → error, exit 1, for every
  runtime value.
- **One call:** `up` and `run` call `docker info` at most once, reading the runtimes and the
  security options together. A failing `docker info` means the daemon is unreachable.
- **Pre-checks, in order:** `docker` on `PATH` (every command except `help` and `version`), then
  for `up`/`run`: `docker info` (daemon, rootless, runtimes), then the guardrails.

## Privilege model

Later sub-issues must not weaken any of these rules.

- The CLI runs as the current user. It never calls `sudo`.
- It writes nothing on the host. Only `install.sh` writes (the install and completion dirs).
  `.vaultrc` and `.vault.env` are only read.
- **Runtime order:** Sysbox when detected; otherwise `--privileged` with the fallback warning.
- **A forced runtime is never swapped.** `--runtime=sysbox` without Sysbox fails.
- **A failed Sysbox run never escalates** to `--privileged`: it exits 1 with docker's error and
  the hint to fix Sysbox or force `--runtime=privileged`.
- **Rootless Docker is refused.**
- **Guardrails** (usage errors, exit 2, checked on flags and `.vaultrc` entries alike):
  - a `-v` whose source is the host's Docker socket is refused: a source whose last path
    component is `docker.sock` (e.g. `/var/run/docker.sock`, `/run/docker.sock`,
    `~/.docker/run/docker.sock`), or the path of a `unix://` `DOCKER_HOST`;
  - a `-p` whose container side is 2375 or 2376 is refused, in every form (`HOST:CONTAINER`,
    `IP:HOST:CONTAINER`, `CONTAINER`, with `/tcp` or `/udp`, or a range that includes them).
- **Install entry:** runs with `--user "$(id -u):$(id -g)"`, with no root, no `--privileged` and
  no `dockerd` ([cli-install.md](cli-install.md)).
- **The image's own needs are unchanged:** Sysbox or `--privileged`, and the inner Docker socket
  stays unix-only.

## Status output

Fields are fixed; the layout is a draft that #24 may adjust (open point 4). stdout, exit 0:

```
name:     vault-my-app
state:    running
image:    darthjee/vault:0.2.0
runtime:  sysbox-runc
ports:    3000->80/tcp
volume:   vault-my-app-data
env:      RAILS_ENV, SECRET_KEY_BASE
```

- `state` is `running`, `stopped` or `not found`. With `not found`, only `name` and `state` are
  printed.
- `runtime` is `sysbox-runc` or `privileged`, read from the container (`docker inspect`).
- `env` lists keys only, never values. No value from an env file is ever printed.

## Diagnostics and exit codes

- **Diagnostics** go to **stderr**, prefixed `vault: error: `, `vault: warning: ` or
  `vault: hint: `. A hint is on its own line, after its error.
- **Normal output** (`status`, `version`, `help`, `already running`, `started`, `removed`) goes
  to stdout, with no prefix.
- **No colours** in this epic.
- Docker's own errors are passed through unchanged (stderr), before the CLI's message.

| Code | Meaning |
|------|---------|
| 0 | Success, including no-ops (`up` already running, `down` on a missing instance, `status` of a missing instance). |
| 1 | Runtime or environment error: docker missing, daemon unreachable, rootless, instance not running, a `docker run` that fails to start the container, a missing `[dir]`, a malformed `.vaultrc`. |
| 2 | Usage error: unknown command or option, bad or missing option value, guardrail refusal, empty sanitized name. |
| passthrough | `compose`, `run` and `up -f` exit with the inner command's exit code once the container has started. |

## Messages

The `vault: ` prefix is omitted; "+" marks a hint line. Tests assert this wording.

| Case | Stream | Message | Exit |
|------|--------|---------|------|
| docker missing | stderr | `error: docker not found in PATH` | 1 |
| daemon unreachable | stderr | `error: cannot reach the Docker daemon` + `is Docker running, and can this user access it?` | 1 |
| rootless daemon | stderr | `error: rootless Docker is not supported` + `see "Supported runtimes" in the README` | 1 |
| Sysbox fallback | stderr | `warning: sysbox-runc not found; running with --privileged (see Security in the README)` | — |
| forced Sysbox missing | stderr | `error: --runtime=sysbox requested but sysbox-runc is not available` | 1 |
| Sysbox run fails | stderr | docker's error, then `error: sysbox-runc failed to start the container` + `fix sysbox or use --runtime=privileged` | 1 |
| port in use | stderr | docker's error + `choose another host port with -p HOST:80` | 1 |
| instance not running | stderr | `error: instance vault-<name> is not running` | 1 |
| already running | stdout | `vault-<name> is already running`, then the status | 0 |
| started (`up`, detached) | stdout | `vault-<name> started` | 0 |
| removed (`down`) | stdout | `vault-<name> stopped and removed (volume vault-<name>-data kept)` | 0 |
| nothing to remove (`down`) | stdout | `vault-<name> does not exist` | 0 |
| dir missing | stderr | `error: directory not found: <dir>` | 1 |
| no compose file | stderr | `warning: no compose file found in <dir>; relying on COMPOSE_FILE` | — |
| bad name | stderr | `error: cannot derive an instance name from '<base>'` + `pass --name <name>` | 2 |
| unknown command | stderr | `error: unknown command '<command>'` + `run "vault help"` | 2 |
| unknown option | stderr | `error: unknown option '<option>'` + `run "vault help"` | 2 |
| missing option value | stderr | `error: <option> requires a value` | 2 |
| bad option value | stderr | `error: invalid value for <option>: '<value>'` | 2 |
| `.vaultrc` unknown key | stderr | `warning: .vaultrc:<line>: unknown key '<key>'` | — |
| `.vaultrc` malformed | stderr | `error: .vaultrc:<line>: expected key=value` | 1 |
| `.vaultrc` bad value | stderr | `error: .vaultrc:<line>: invalid value for <key>: '<value>'` | 1 |
| docker.sock guardrail | stderr | `error: refusing to mount the Docker socket (<src>)` | 2 |
| port 2375/2376 guardrail | stderr | `error: refusing to publish the Docker daemon port <port>` | 2 |
| install dir not writable | stderr | `error: <dir> is not writable` | 1 |
| install dir not in PATH | stderr | `warning: <dir> is not in PATH; add: export PATH="<dir>:$PATH"` | — |

- "No compose file" means none of `compose.yaml`, `compose.yml`, `docker-compose.yaml`,
  `docker-compose.yml` exists in `<dir>`. It is checked only when `<dir>` is mounted.
- `<value>` in "bad value" messages is never an env value: `-e` / `env=` values are passed to
  docker as given (`KEY=VALUE` or `KEY`), not validated, and never echoed.
- Install messages: [cli-install.md → Messages](cli-install.md#messages).

## Edge cases

| # | Case | Behaviour | Implemented in |
|---|------|-----------|----------------|
| 1 | `docker` not installed, or the daemon unreachable | Fail fast: `docker not found in PATH` / `cannot reach the Docker daemon`, exit 1. | #23 |
| 2 | Sysbox listed, but the run with `sysbox-runc` fails | docker's error + `sysbox-runc failed to start the container` + hint, exit 1. **Never** escalate to `--privileged`. | #24 |
| 3 | `--runtime=sysbox` forced, but Sysbox is not available | Fail with the forced-Sysbox error, exit 1. No fallback. | #23 |
| 4 | `up` when `vault-<name>` is already running | No-op: `already running` plus the status, exit 0. | #24 |
| 5 | `up` when `vault-<name>` exists but is stopped | `docker rm`, then a fresh `docker run` with the current flags. The volume is kept. | #24 |
| 6 | Host port already in use | docker's error + the `-p` hint, exit 1. | #24 |
| 7 | `logs` / `compose` / `status` on a missing or stopped instance | `instance vault-<name> is not running`, exit 1; `status` reports it, exit 0. `down` on a missing instance exits 0. | #24 |
| 8 | `[dir]` missing, or no compose file in it | A missing dir fails (exit 1). A missing compose file only warns (`COMPOSE_FILE` may point elsewhere). | #24 |
| 9 | Basename is not a valid container name | Sanitized to `[a-z0-9_.-]`; an empty result fails and asks for `--name` (exit 2). | #23 |
| 10 | Two names resolving to the same data volume | Not detected; documented in the README (#29). | — (docs, #29) |
| 11 | `.vaultrc` unknown keys or malformed lines | Unknown keys warn; malformed lines fail, naming the line (exit 1). | #23 |
| 12 | `.vault.env` and `--env-file` both present | Both passed, `.vault.env` first, so explicit files win. | #23 |
| 13 | `install.sh` target dir not writable, or not in `PATH` | Not writable fails (exit 1). Not in `PATH`: installed, with a warning showing the line to add. | #26 |
| 14 | CLI version ≠ image version (with `--image`) | No check: `--image` is the user's choice. | #23 (no check) |

## Performance

- `docker info` (about 100–300 ms) is called only by `up` and `run`, at most once each. `logs`,
  `status`, `compose` and `down` never call it.
- `vault up` (detached) returns right after `docker run -d`, without waiting for the inner
  `dockerd` or stack. `status` and `logs -f` show progress. `--wait` is future work.
- **Stop timeout:** one value, default **60 s**, used for `docker run --stop-timeout` and
  `docker stop -t`. Override with `--stop-timeout N` or `stop-timeout=` in `.vaultrc`.

## Shell completion

Owned by #25; internals are left to it.

- `cli/completion/vault.bash` (bash 3.2 compatible) and `cli/completion/_vault` (zsh) complete:
  - the subcommands;
  - the options of each subcommand, including the `--runtime` values `auto`, `sysbox`,
    `privileged`;
  - directories for `[dir]`.
- Install locations: [cli-install.md](cli-install.md).

## Notes for the README

For #29:

- The CLI section links to the existing **Security** section, and explains when the CLI uses
  `--privileged` (the automatic fallback) and how to force Sysbox (`--runtime=sysbox`).
- It documents the Docker Desktop shared file paths: `[dir]` and `-v` sources must be shared.
  This is documented, not checked.
- It documents that two instances must not share a data volume (edge case 10).
- It shows a download-and-verify alternative to `curl | bash`, using `SHA256SUMS`.
