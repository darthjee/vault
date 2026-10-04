# vault

[![Build Status](https://circleci.com/gh/darthjee/vault.svg?style=shield)](https://circleci.com/gh/darthjee/vault)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/02d1416cf9bf43478c2b66d09361158a)](https://app.codacy.com/gh/darthjee/vault/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

**Current Version:** 0.0.1

Vault is a Docker-in-Docker image that runs a `docker compose` stack inside a
single container. An application and its dependencies (database, cache, ...)
ship as one stand-alone image that exposes one port.

```
host --(-p 8080:80)--> Vault container (dockerd + compose)
                         |-- app  (ports: ["80:3000"])
                         `-- db   (no published ports)
```

On boot, Vault starts its own Docker daemon, optionally preloads image tarballs,
runs `docker compose` from `/vault`, and exits with compose's exit code.

Images are published on Docker Hub as
[`darthjee/vault`](https://hub.docker.com/r/darthjee/vault).

## CLI

The `vault` CLI runs a Vault image on your host for you: it builds the
`docker run` command (runtime, mounts, data volume, ports, env) from a project
directory and manages the resulting container.

```bash
cd my-stack            # a directory with a compose file
vault up               # start it, detached, on http://localhost:3000
vault status           # state, image, runtime, ports, volume, env keys
vault compose ps       # run "docker compose ps" inside the instance
vault logs -f          # follow the logs
vault down             # stop and remove it (the data volume is kept)
```

Every command also takes the project directory as an argument
(`vault up ./my-stack`); without it, the current directory is used.

**Supported platforms:** Linux and macOS, with bash 3.2 or later (the stock
macOS bash works). Windows is not supported.

### Install

The CLI is installed with a one-liner:

```bash
curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash
```

The installer needs Docker and never runs `sudo`. It pulls
`darthjee/vault:<version>` and copies the CLI out of that image, so the CLI
always matches the image version. By default it installs:

- the CLI into `~/.local/bin/vault`;
- the shell completions into `~/.local/share/vault/completion/`.

Running it again upgrades the CLI in place.

The copy is done by the image's `vault-install` entry, run as the current
user with no root, no `--privileged` and no inner Docker daemon. It is an
image entry point used by `install.sh`, not a `vault` subcommand.

#### Installer variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `VAULT_VERSION` | the release's version | Version of the CLI (and image) to install. |
| `VAULT_INSTALL_DIR` | `$HOME/.local/bin` | Where the `vault` CLI is installed. |
| `VAULT_IMAGE` | `darthjee/vault:$VAULT_VERSION` | Image the CLI is copied from. |

Pin a version:

```bash
curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh \
  | VAULT_VERSION=0.0.1 bash
```

These variables only affect the installer: the installed CLI reads none of
them.

#### Completion and PATH

Enable completion in your shell:

```bash
# bash (~/.bashrc)
source ~/.local/share/vault/completion/vault.bash

# zsh (~/.zshrc, before compinit)
fpath=(~/.local/share/vault/completion $fpath)
```

Completion covers the commands, their options, `--runtime` values, files for
`--env-file` and `-v`, directories for `[dir]`, and existing instance names
for `--name`.

If the install dir is not in `PATH`, the installer warns and prints the line
to add, e.g. `export PATH="$HOME/.local/bin:$PATH"`. The install still
succeeds.

#### Download and verify

Release tags are not immutable, and `curl | bash` runs whatever the URL
serves. Each GitHub release publishes these assets:

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

### Commands

```
vault <command> [options] [dir] [args]
```

| Command | Behaviour |
|---------|-----------|
| `vault up [options] [dir]` | Starts the instance `vault-<name>`. Detached by default (prints `vault-<name> started`); `-f` / `--attach` runs it in the foreground, where Ctrl+C triggers the graceful shutdown. Already running: no-op, prints the status. Stopped: removed, then started again with the current options (the data volume is kept). |
| `vault down [options] [dir]` | Stops (`docker stop -t <stop-timeout>`) and removes the instance. The data volume is **never** removed. A missing instance is not an error. |
| `vault logs [options] [-f] [dir]` | Shows the instance logs; `-f` / `--follow` follows them. Fails when the instance is not running. |
| `vault status [options] [dir]` | Prints the name, state (`running`, `stopped`, `not found`), image, runtime, ports, volume and env keys (never values). Exits 0 whatever the state. |
| `vault compose [options] <args>` | Runs `docker compose <args>` inside the running instance, e.g. `vault compose ps`. Fails when the instance is not running. |
| `vault run [options] [dir] <args>` | One-shot `docker run --rm` in the foreground, passing `<args>` to the image (e.g. `vault run config`). Refused while the instance is running, since both would share its data volume. |
| `vault version` | Prints `vault X.Y.Z`. |
| `vault help` | Prints the usage. `-h` / `--help` works on every command. |

- `compose` and `run` stop parsing options at the first argument that is not
  a CLI option; it and everything after it go to `docker compose`.
- For `run`, the first positional argument is `[dir]` only if it is an
  existing directory; otherwise it is the first compose argument. Put `--`
  before an argument that happens to name a directory: `--` ends the options.
- `compose`, `run` and `up -f` exit with the inner command's exit code.
  Otherwise the CLI exits `0` on success, `1` on a runtime or environment
  error (e.g. Docker unreachable, instance not running) and `2` on a usage
  error (e.g. unknown option, refused volume or port).
- Messages go to stderr, prefixed `vault: error:`, `vault: warning:` or
  `vault: hint:`.

### Instances

Each project runs as one named instance. The name is, in order:

1. `--name`, else `name=` in `.vaultrc`;
2. else, with `--image` and no `[dir]`, the image name without registry, path
   and tag (`registry.example.com/team/my-app:1.0` gives `my-app`);
3. else the basename of `[dir]` (else of the current directory).

Derived names are lowercased and stripped of any character outside
`[a-z0-9_.-]` (`My App!` gives `myapp`). Explicit names must match
`[a-z0-9][a-z0-9_.-]*`.

The name gives the container `vault-<name>` and the data volume
`vault-<name>-data`, mounted on `/var/lib/docker` (see
[Persistence](#persistence)).

> **Warning:** two instances must never share a data volume. Two project
> directories with the same basename (e.g. `~/a/app` and `~/b/app`) both
> resolve to `vault-app-data`. The CLI does not detect it: pass `--name` (or
> set `name=` in `.vaultrc`) to tell them apart.

### Runtime

`up` and `run` pick the runtime with `--runtime` (default `auto`):

| `--runtime` | Sysbox available | Result |
|-------------|------------------|--------|
| `auto` | yes | `--runtime=sysbox-runc`. |
| `auto` | no | `--privileged`, with a warning. |
| `sysbox` | yes | `--runtime=sysbox-runc`. |
| `sysbox` | no | Error, exit 1. No fallback. |
| `privileged` | either | `--privileged`, no warning. |

- Sysbox is detected when `docker info` lists the `sysbox-runc` runtime.
- Use `--runtime=sysbox` to make sure the CLI never falls back to
  `--privileged`.
- If a run with Sysbox fails to start, the CLI never retries with
  `--privileged`: it shows docker's error and a hint to fix Sysbox or force
  `--runtime=privileged`.
- Rootless Docker is refused, whatever the runtime.

Read [Security](#security) before using `--privileged`.

### Options and configuration

| Option | Commands | Default | Meaning |
|--------|----------|---------|---------|
| `--name <name>` | all | see [Instances](#instances) | Instance name. |
| `--image <image>` | all | `darthjee/vault:<CLI version>` | Image to run. On `down`, `logs`, `status` and `compose` it only feeds the name default. |
| `--runtime <auto\|sysbox\|privileged>` | `up`, `run` | `auto` | See [Runtime](#runtime). |
| `-p`, `--port <HOST:CONTAINER>` | `up`, `run` | `3000:80` | Published port; repeatable. |
| `-v`, `--volume <SRC:DST>` | `up`, `run` | none | Extra mount; repeatable. |
| `-e`, `--env <KEY=VALUE>` | `up`, `run` | none | Env var for the Vault container; repeatable. |
| `--env-file <file>` | `up`, `run` | none | Env file; repeatable. |
| `--stop-timeout <seconds>` | `up`, `run`, `down` | `60` | Seconds to wait for the graceful shutdown before docker kills the container. |
| `-f`, `--attach` | `up` | off | Run in the foreground. |
| `-f`, `--follow` | `logs` | off | Follow the logs. |

The [environment variables](#environment-variables) of the image
(`COMPOSE_UP_ARGS`, `VAULT_DOCKERD_TIMEOUT`, `COMPOSE_FILE`, other
`COMPOSE_*`) are passed with `-e` or an env file; the CLI does not interpret
them:

```bash
vault up -e COMPOSE_UP_ARGS="--abort-on-container-exit" -p 8080:80
```

#### `.vault.env`

When `.vault.env` exists in `[dir]` (else in the current directory), `up` and
`run` pass it as the first `--env-file`, so explicit env files and `-e` win
over it. The CLI never reads its content; docker does.

#### `.vaultrc`

Per-project defaults live in `.vaultrc`, read from `[dir]` (else from the
current directory):

```
# .vaultrc
name=my-app
image=darthjee/vault:0.0.1
runtime=sysbox
port=3000:80
port=3443:443
volume=./shared:/shared
env=RAILS_ENV=production
env-file=.env.prod
stop-timeout=90
```

- Keys mirror the long options: `name`, `image`, `runtime`, `port`, `volume`,
  `env`, `env-file`, `stop-timeout`. `port`, `volume`, `env` and `env-file`
  are repeatable (one entry per line); for the others the last line wins.
- One `key=value` per line. The value is taken verbatim: no quoting, no
  variable expansion, no `~` expansion. `#` starts a comment only at the
  beginning of a line.
- The file is parsed, **never sourced**: it cannot run commands.
- Relative `volume` sources (starting with `.` or containing `/`) and
  relative `env-file` paths resolve against the directory holding `.vaultrc`.
  A bare volume name (`data:/data`) stays a named volume. Relative paths given
  as flags are passed to docker as given.
- `image=` changes the image only: unlike `--image`, it does not change the
  name default nor skip the `/vault` mount.
- **Precedence:** flags > `.vaultrc` > built-in defaults. For repeatable keys,
  any flag replaces every `.vaultrc` entry of that key (one `-p` drops all
  `port=` lines).
- An unknown key warns and is skipped. A line without `=` or an invalid value
  fails, naming the line number.

#### Guardrails

Checked on flags and `.vaultrc` entries alike (usage error, exit 2):

- a volume whose source is the host's Docker socket (any path ending in
  `docker.sock`, or the socket of a `unix://` `DOCKER_HOST`) is refused;
- a port whose container side is, or whose range covers, `2375` or `2376`
  (the Docker daemon ports) is refused.

### Baked images

For an image that already holds its stack (see
[Shipping a stack as its own image](#shipping-a-stack-as-its-own-image)),
pass `--image` without a `[dir]`:

```bash
vault up --image my-app -p 8080:80
```

Nothing is mounted on `/vault`, and the instance is named after the image
(`vault-my-app`). Pass a `[dir]` to mount it anyway.

### Docker Desktop

On Docker Desktop, the project directory and every `-v` source must be in
Docker Desktop's shared file paths (Settings > Resources > File sharing). The
CLI does not check it.

## Usage

### Running

Mount your compose project at `/vault` and publish the port your app binds
inside the container.

Recommended, with the [Sysbox](https://github.com/nestybox/sysbox) runtime:

```bash
docker run --runtime=sysbox-runc \
  -v "$PWD/my-stack:/vault" \
  -v vault-data:/var/lib/docker \
  -p 8080:80 \
  darthjee/vault
```

Fallback, with `--privileged` (read [Security](#security) first):

```bash
docker run --privileged \
  -v "$PWD/my-stack:/vault" \
  -v vault-data:/var/lib/docker \
  -p 8080:80 \
  darthjee/vault
```

### Shipping a stack as its own image

Instead of mounting the project, bake it into a derived image:

```dockerfile
FROM darthjee/vault
COPY . /vault
```

```bash
docker build -t my-app .
docker run --runtime=sysbox-runc -p 8080:80 my-app
```

### Arguments

With no arguments the container runs `docker compose up` (plus
`COMPOSE_UP_ARGS`). Any arguments are passed to `docker compose` instead:

```bash
docker run --privileged -v "$PWD/my-stack:/vault" darthjee/vault config
docker run --privileged -v "$PWD/my-stack:/vault" darthjee/vault ps
docker run --privileged -v "$PWD/my-stack:/vault" -p 8080:80 darthjee/vault up --build
```

### Ports

An inner service publishes its port inside the Vault container, and you map
that port to the host with `-p`:

```yaml
# /vault/docker-compose.yml
services:
  app:
    image: my-app
    ports: ["80:3000"]   # inner port 3000 -> Vault port 80
  db:
    image: postgres:17   # no published ports
```

```bash
docker run ... -p 8080:80 darthjee/vault   # host 8080 -> Vault 80 -> app 3000
```

The image declares `EXPOSE 80` as a convention only. Databases and other
internal services should not publish ports. Vault has no built-in reverse
proxy.

### Persistence

The image declares `VOLUME /var/lib/docker`. Mount a named volume there to
keep pulled images and inner named volumes (e.g. database data) across
restarts:

```bash
docker run ... -v vault-data:/var/lib/docker darthjee/vault
```

Without it, every start pulls the images again and inner data is lost with
the container.

### Offline preload

Every `/vault/images/*.tar` is loaded with `docker load` before compose
starts, so the stack can run without pulling. Create them with
`docker save -o images/my-app.tar my-app`. A missing `/vault/images` folder
is skipped. To prevent pulls entirely, set `COMPOSE_UP_ARGS="--pull never"`
or use `pull_policy:` in the compose file.

### Bind mounts

Bind mounts in the inner compose file refer to the **Vault container's**
filesystem, not the host's. Anything the inner stack needs must first be
mounted (or copied) into the Vault container, usually under `/vault`.
Relative paths resolve against `/vault`.

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `COMPOSE_FILE` | compose default | Compose file(s) to use; a `:`-separated list is allowed. |
| `COMPOSE_PROJECT_NAME` | compose default | Compose project name. |
| `COMPOSE_UP_ARGS` | empty | Extra arguments for the default `up`, e.g. `--abort-on-container-exit` or `--pull never`. Split on whitespace, with **no quoting support**. |
| `VAULT_DOCKERD_TIMEOUT` | `30` | Seconds to wait for the inner `dockerd` to start. Must be a positive integer. |

Any other `COMPOSE_*` variable understood by `docker compose` works as usual.

## Behaviour

- **Exit code:** the container exits with compose's exit code.
- **Service failures:** the container only exits when compose exits.
  Individual service crashes are handled by compose `restart:` policies. To
  fail fast, set `COMPOSE_UP_ARGS="--abort-on-container-exit"`.
- **Shutdown:** SIGTERM / SIGINT (e.g. `docker stop`, Ctrl+C) run
  `docker compose down`, then stop the inner daemon. This can take longer than
  `docker stop`'s default 10s grace period, after which Docker kills the
  container. Give it more time with `docker stop -t 60 <container>`, or
  `docker run --stop-timeout 60 ...`.
- **Do not share `/var/lib/docker`:** never mount the same `/var/lib/docker`
  volume into two running Vault containers. Vault does not detect it, and
  both daemons will corrupt each other's state.
- **Startup errors** (exit code `1`, message on stderr):
  - `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?`
    — the container lacks the privileges Docker-in-Docker needs, or `dockerd`
    did not become ready within `VAULT_DOCKERD_TIMEOUT` seconds.
  - `VAULT_DOCKERD_TIMEOUT must be a positive integer, got: '<value>'`
  - `failed to load image tarball: <file>` — a preload tarball could not be
    loaded.

## Supported runtimes and platforms

- **Supported:** the Sysbox runtime (`--runtime=sysbox-runc`, recommended)
  and `--privileged` (fallback), on Docker Desktop and Linux hosts.
- **Unsupported:** rootless Docker, hand-picked capabilities (`--cap-add`),
  and mounting the host's `docker.sock` instead of running an inner daemon.
- **Managed platforms:** Vault does not run on most of them (ECS Fargate,
  Cloud Run, Kubernetes without privileged pods), since they refuse
  privileged containers.
- **Architectures:** images are published for `linux/amd64` and
  `linux/arm64`.

## Security

Running a Docker daemon inside a container needs elevated privileges. Know
the trade-offs before you deploy Vault.

- **`--privileged` is dangerous.** It disables most of the isolation between
  the container and the host:
  - a process that escapes the container is effectively root on the host;
  - the container gets access to all host devices;
  - seccomp and AppArmor profiles are disabled;
  - most managed platforms refuse privileged containers.
- **Processes run as root** inside the Vault container (the inner daemon
  needs it), and inner containers run under that daemon.
- **Prefer Sysbox.** With `--runtime=sysbox-runc`, the container runs in its
  own user namespace: root inside the container is not root on the host, and
  no `--privileged` flag is needed.
- **The inner Docker socket is never exposed over TCP.** Vault starts
  `dockerd` with an explicit unix `--host` only. Never add a TCP listener or
  publish port 2375: anyone reaching it controls the daemon.
- **Do not mount the host's `docker.sock`** into Vault: it is unsupported and
  hands the host's Docker daemon to the inner stack.

## Development

Requirements: Docker and Make. Lint and unit tests run in pinned tool images.

```bash
make bundle-cli    # bundle cli/ into build/vault
make build-image   # bundle the CLI, then build darthjee/vault:dev
make lint          # shellcheck
make test          # bats unit tests (CLI tests also run under bash 3.2)
make test-image    # build, then smoke-test the image (needs Docker with --privileged)
make test-cli-e2e  # build, then drive a real instance with build/vault and test install.sh
```

Contributor and agent documentation lives in [AGENTS.md](AGENTS.md) and
[`docs/agents/`](docs/agents/).

## License

See [LICENSE](LICENSE).
