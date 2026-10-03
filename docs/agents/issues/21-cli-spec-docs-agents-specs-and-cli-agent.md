# Issue: CLI spec (docs/agents/specs) and cli agent

## Description
Part of epic #20 (Vault CLI), and its first sub-issue: it depends on nothing. Agents:
- `product-owner` writes the spec;
- `architect` creates the agent.

Only documentation and agent definitions change: no code, Makefile or CI.

## Problem
The CLI design lives only in the body of epic #20. Several shared contracts are still open, and
the later sub-issues need one agreed reference:
- the `.vaultrc` keys;
- the in-image paths of the CLI and the install entry;
- the Make target names;
- the CLI's internal module boundaries;
- the exact user-facing messages and exit codes.

There is also no specialist agent that owns the CLI code yet.

## Expected Behavior
- `docs/agents/specs/*.md` exist, as six flat files (see Spec files below). Together they:
  - record every decision from epic #20 (language and bash 3.2 target, command surface,
    volumes and config, edge cases, runtime and guardrails, release and CI, repo layout,
    testing strategy);
  - fix the shared contracts: the `.vaultrc` keys and format, the bundle path `build/vault`, the
    in-image paths of the CLI, completions and install entry, the Make targets
    (bundle, `test-cli-e2e`, `github-release`), the `github` CircleCI context, and
    the `VAULT_VERSION` line format;
  - include a sub-issue map (epic #20 sub-issues → spec sections) and the list of open points.
- `AGENTS.md` gets a `specs/` row in its documentation table, and a note: "During epic #20,
  `docs/agents/specs/*.md` overrides these docs where they conflict."
- `.claude/agents/cli.md` exists, the existing agent files are adjusted, and the `AGENTS.md`
  agents table lists `cli` (see `cli` agent and ownership changes below).
- The spec is a working document: a later PR that deviates from it updates it in the same PR.
  The last sub-issue of #20 deletes it.
- No tests (documentation only).

## Solution

### Scope
**The spec decides (shared contracts and behaviour):**
- **CLI interface:** every command, flag and default, the precedence rules (flags > `.vaultrc` >
  built-in defaults), and the instance naming and sanitizing rule.
- **`.vaultrc`:** the format, the full key list, and the parsing rules (never `source`d).
- **Runtime selection:** Sysbox detection, the fallback to `--privileged`, forcing a runtime,
  rootless detection, when the warning is shown, and the guardrails (docker.sock mounts, ports
  2375/2376).
- **User-facing messages and exit codes:** for every edge case listed in #20.
- **Paths:**
  - the source layout (`cli/`, `install.sh`, `test/cli/`, `test/install/`);
  - the bundle path `build/vault`;
  - the in-image paths of the CLI, the completion files and the install entry.
- **Make targets and scripts:**
  - names and behaviour: bundle, the bash 3.2 test run, `test-cli-e2e`, `github-release`;
  - the `VAULT_VERSION` line format and the version-check rule.
- **CI:** job names and order, the `github` context, and the list of released artifacts.
- **`install.sh` contract:** its env vars (`VAULT_VERSION`, the target dir variable), defaults
  and behaviour.
- **Agent ownership** of every new path.
- **A sub-issue map** (#22–#30 → spec sections), and a list of open points.

**It leaves to each sub-issue:**
- library file names inside `cli/lib/` and their function names and signatures;
- the list of test cases;
- the exact Makefile recipes, CircleCI YAML and Dockerfile lines;
- README and Docker Hub prose;
- the internals of the completion scripts.

**Out of scope for #21:** any code, Makefile, CI or Dockerfile change. Only `docs/agents/specs/*.md`,
`.claude/agents/cli.md` and `AGENTS.md` change.

### Spec files
Six flat files directly in `docs/agents/specs/`, each with a `cli-` prefix:

| File | Contents | Main readers |
|------|----------|--------------|
| `cli-overview.md` | Goals; principles (bash 3.2, config never `source`d, never escalate privileges silently); source, bundle and in-image paths; agent ownership; sub-issue map (#22–#30 → sections); open points | all |
| `cli-commands.md` | Every command and flag, with defaults; instance naming; runtime selection and guardrails; messages and exit codes; the edge-case table | #23, #24, #25 |
| `cli-config.md` | `.vaultrc` format and keys; `.vault.env`; precedence; parsing errors | #23 |
| `cli-install.md` | What the image ships and where; the install entry contract; `install.sh` env vars and behaviour; completion file locations | #26 |
| `cli-tooling.md` | The `VAULT_VERSION` line and version checks; the bundle script and target; the bash 3.2 test image; lint/test coverage; testing strategy (stub `docker`, e2e flow) | #22, #27 |
| `cli-ci.md` | PR pipeline changes; where `test-cli-e2e` runs; the `github-release` job; the `github` context; released artifacts | #27, #28 |

### Contracts fixed by this issue
The spec writes these up as decided. They are not open points.

#### `.vaultrc`
```
# .vaultrc
name=my-app
image=darthjee/vault:0.2.0
runtime=sysbox
port=3000:80
port=3443:443
volume=/data/shared:/shared
env=RAILS_ENV=production
env-file=.env.prod
```
- **Keys:** lowercase, mirroring the long flags: `name`, `image`, `runtime`
  (`auto|sysbox|privileged`, default `auto`), `port`, `volume`, `env`, `env-file`,
  `stop-timeout` (seconds, default `60`).
- **Lists:** `port`, `volume` and `env` are **repeatable**, and each line adds one entry. Values
  are never split on whitespace, so paths with spaces work.
- **Parsing:**
  - the value is everything after the first `=`, taken verbatim (no quoting, no escape
    handling);
  - `#` starts a comment only at the beginning of a line, and blank lines are ignored;
  - the file is never `source`d;
  - an unknown key warns, and a line without `=` fails, naming the line number.
- **Precedence:** flags > `.vaultrc` > built-in defaults.
  - For list keys, **flags replace per key**: any `-p` replaces every `.vaultrc` `port`; the same
    holds for `-v` / `volume` and `-e` / `env`.
  - `.vault.env` is independent of this: it is passed as `--env-file` when present, before any
    `env-file` or `--env-file`.

#### In-image paths
| Path | Contents |
|------|----------|
| `/usr/local/bin/vault` | The bundled CLI. |
| `/usr/local/bin/vault-install` | The install entry (from `source/bin/install.sh`). |
| `/usr/local/share/vault/completion/vault.bash`, `_vault` | Completion files. |
| `/install` | The bind-mount target that the install entry copies into. |

#### Make targets and scripts
| Target | Script | Behaviour |
|--------|--------|-----------|
| `bundle-cli` | `scripts/bundle_cli.sh` | Builds the single executable `build/vault` (git-ignored). |
| `test` | `scripts/test.sh` | Runs bats on both the current `BATS_IMAGE` and the bash 3.2 image (new variable `BASH32_TEST_IMAGE`, built from `test/bash32/Dockerfile`: `FROM bash:3.2` + pinned bats-core). |
| `test-cli-e2e` | `scripts/test_cli_e2e.sh` | End-to-end test against the built image (see #27). |
| `github-release TAG=x` | `scripts/github_release.sh` | Creates the GitHub release and uploads the assets. Fails fast without `TAG`. |

#### Version line
- `VAULT_VERSION="X.Y.Z"` appears in both `cli/bin/vault` and `install.sh`.
- `scripts/bump_version.sh` updates both, and `scripts/check_tag_version.sh` checks both, alongside
  `VERSION` and the README line.

#### `install.sh`
| Env var | Default | Purpose |
|---------|---------|---------|
| `VAULT_VERSION` | its own stamped version | The version to install. |
| `VAULT_INSTALL_DIR` | `~/.local/bin` | Where `vault` is copied. |
| `VAULT_IMAGE` | `darthjee/vault:$VAULT_VERSION` | The image to install from. The e2e test overrides it with the local build. |

The completion files go to `~/.local/share/vault/completion/`, and the script prints the line to
source them.

#### CI
- Job `github-release`, in the CircleCI context `github`, with the env var `GITHUB_TOKEN`.
- Released assets: `vault`, `install.sh`, `vault.bash`, `_vault`, plus `SHA256SUMS` covering all of
  them.

#### Bundling rule
- `cli/bin/vault` sources the libraries through one marked block (`# BEGIN LIBS` … `# END LIBS`).
- `scripts/bundle_cli.sh` replaces that block with the content of `cli/lib/*.sh`, concatenated
  in a fixed order, and writes the result to `build/vault`.
- `cli-tooling.md` documents the rule, and both `cli` and `automation` follow it.

### `cli` agent and ownership changes
**`.claude/agents/cli.md`** (same shape as `dev.md`; tools: `Read, Edit, Write, Bash`):
- **Owns:**
  - `cli/bin/vault`, `cli/lib/*.sh` and `cli/completion/*`;
  - `install.sh` at the repo root (an explicit exception to the architect's root-level
    ownership);
  - `test/cli/` and `test/install/`.
- **Must not touch** the paths below; it reports any change it needs there to their owner:
  - `Dockerfile`, `source/`, `test/lib/` and `test/fixture/` (owned by `dev`);
  - `Makefile`, `scripts/`, `.circleci/`, `VERSION` and `test/bash32/` (owned by `automation`);
  - `docs/agents/` (owned by `product-owner`).
- **Conventions:**
  - bash 3.2 only: no associative arrays, `mapfile`, `${var,,}`, `declare -n` or `[[ -v ]]`;
  - `set -euo pipefail` in `bin/vault` only;
  - libraries only define functions, prefixed by module (as in `contributing.md`);
  - only `bin/vault` reads the environment and `.vaultrc`;
  - `docker` is wrapped so bats can stub it;
  - `.vaultrc` is never `source`d;
  - the bundling rule above.
- **Commands:** `make lint`, `make test`, `make bundle-cli`, `make test-cli-e2e`.

**Changes to existing agents:**
- `dev.md`: its `test/` scope narrows to `test/lib/`, `test/fixture/` and the image tests, and it
  adds `source/bin/install.sh` (the in-image install entry).
- `automation.md`: adds `test/bash32/` (the bash 3.2 test image) and the new top-level `build/`
  folder (the git-ignored bundle output from `scripts/bundle_cli.sh`), including its `.gitignore`
  entry, added in #22.
- `architect.md`: notes that `install.sh` at the root belongs to `cli`.
- The `AGENTS.md` agents table lists `cli`, with the updated scopes.

### Edge cases
| # | Case | Handling |
|---|------|----------|
| 1 | The spec and the body of epic #20 disagree | Once merged, the spec is the source of truth. The epic body is not kept in sync. |
| 2 | The spec and the current agent docs (`AGENTS.md`, `flow.md`, …) disagree | The spec wins during epic #20, per the override note in `AGENTS.md`. #29 syncs the agent docs. |
| 3 | A later sub-issue has to deviate from the spec | That PR updates the spec in the same PR. |
| 4 | Writing the spec raises a question that can't be settled here | It is listed under **Open points** in `cli-overview.md`, naming the sub-issue that must settle it. It does not block #21. |
| 5 | Sub-issues are added, merged or renumbered later | Whoever changes the split updates the sub-issue map in `cli-overview.md`. |
| 6 | CLI edge-case coverage | `cli-commands.md` holds the full 14-case table from #20, with an **Implemented in** column (#23 / #24 / #26), as in the docker-image spec (#3). |
| 7 | `docs/agents/specs/` does not exist (it was removed by #10) | #21 creates it fresh. #30 deletes the folder if it ends up empty. |

### Backward compatibility
- **This issue:** documentation and agent definitions only.
  - No change to the image, the entrypoint, the Makefile, CI or released artifacts.
  - No configuration under `.claude/` references agent names, so narrowing the `dev` and
    `automation` scopes and adding `cli` breaks no tooling.
- **The `AGENTS.md` override note** is temporary: it applies only while epic #20 is open, and #30
  removes it with the spec.
- **Compatibility statement inside the spec:** `cli-overview.md` must state the compatibility
  guarantees that later sub-issues are held to:
  - the image's default behaviour (`docker run darthjee/vault` → compose up, passthrough args,
    env vars, exit codes, signals) is **unchanged**. The image only gains files (the CLI,
    `vault-install`, completions);
  - plain `docker run` usage, as documented in the README today, keeps working, and the CLI is
    optional;
  - existing Make targets keep their names. `make test` is extended (it adds the bash 3.2 run)
    but not renamed;
  - the release chain keeps its existing jobs. `github-release` is added after
    `build-and-release`, and a failure there does not unpublish the Docker image;
  - `VERSION` stays the single version source. The image and CLI share it.

### Messages and exit codes
**Fixed by this issue (contracts):**
- **Diagnostics:**
  - all go to **stderr**, prefixed `vault: error: `, `vault: warning: ` or `vault: hint: `;
  - a hint goes on its own line, after the error.
- **Normal output** (`status`, `version`, `already running`) goes to stdout, with no prefix.
- **No colours** in this epic.
- **Exit codes:**

  | Code | Meaning |
  |------|---------|
  | 0 | Success, including no-ops (`up` already running, `down` on a missing instance). |
  | 1 | Runtime or environment error (docker missing, unreachable daemon, rootless, instance not running, run failed, malformed `.vaultrc`). |
  | 2 | Usage error (unknown command or flag, bad flag value, guardrail refusal, empty sanitized name). |
  | passthrough | `compose`, `run` and `up -f` exit with the inner command's exit code. |

**Draft wording** (written into `cli-commands.md` as the starting point; the spec PR may polish it,
and from then on tests assert the spec's wording). Each `vault: ` prefix is omitted below, and
"+" marks a hint line:

| Case | Message |
|------|---------|
| docker missing | `error: docker not found in PATH` |
| daemon unreachable | `error: cannot reach the Docker daemon` + `is Docker running, and can this user access it?` |
| rootless daemon | `error: rootless Docker is not supported` + `see "Supported runtimes" in the README` |
| Sysbox fallback | `warning: sysbox-runc not found; running with --privileged (see Security in the README)` |
| forced Sysbox missing | `error: --runtime=sysbox requested but sysbox-runc is not available` |
| Sysbox run fails | docker's error, then `error: sysbox-runc failed to start the container` + `fix sysbox or use --runtime=privileged` |
| port in use | docker's error + `choose another host port with -p HOST:80` |
| instance not running | `error: instance vault-<name> is not running` |
| already running | stdout: `vault-<name> is already running`, followed by the status |
| dir missing | `error: directory not found: <dir>` |
| no compose file | `warning: no compose file found in <dir>; relying on COMPOSE_FILE` |
| bad name | `error: cannot derive an instance name from '<base>'` + `pass --name <name>` |
| `.vaultrc` unknown key | `warning: .vaultrc:<line>: unknown key '<key>'` |
| `.vaultrc` malformed | `error: .vaultrc:<line>: expected key=value` |
| docker.sock guardrail | `error: refusing to mount the Docker socket (<src>)` |
| port 2375/2376 guardrail | `error: refusing to publish the Docker daemon port <port>` |
| install dir not writable | `error: <dir> is not writable` |
| install dir not in PATH | `warning: <dir> is not in PATH; add: export PATH="<dir>:$PATH"` |

### Runtime privileges & host impact
- **This issue:** none. It changes only docs and agent definitions, and nothing changes what any
  container needs from the host.
- **The spec must carry the privilege model**, in a dedicated section of `cli-commands.md`
  (summarised in `cli-overview.md` → principles), so that later sub-issues cannot weaken it:
  - the CLI runs as the current user, never calls `sudo`, and writes nothing on the host except
    through `install.sh`;
  - runtime order: Sysbox when detected, otherwise `--privileged` with the fallback warning; a
    forced runtime is never silently swapped; a failed Sysbox run **never** escalates to
    `--privileged`;
  - a rootless daemon is refused;
  - guardrails: no host Docker socket mounts, and no publishing of container ports 2375/2376;
  - the install entry runs with `--user "$(id -u):$(id -g)"`, without root, `--privileged` or
    `dockerd`;
  - the image's own privilege needs are unchanged (Sysbox or `--privileged`, unix socket only).
- **For #29:** the spec tells the README CLI section to link to the existing **Security** section,
  and to explain when the CLI uses `--privileged` and how to force Sysbox.

### Performance & security
**Performance:**
- **`docker info`** (about 100–300 ms) is called only by commands that create a container (`up`,
  `run`). `logs`, `status`, `compose` and `down` never call it.
- **`vault up`** (detached) returns right after `docker run -d`, without waiting for the inner
  `dockerd` or stack; `status` and `logs -f` show progress. A `--wait` flag is listed under future
  work in the spec, and is not part of this epic.
- **Stop timeout:** a single value, default **60 s**, is used both for `--stop-timeout` on
  `docker run` and for `docker stop -t` in `down`. It can be overridden with `--stop-timeout N`
  or `stop-timeout=` in `.vaultrc`.
- **`install.sh`** pulls the full image to copy one file. This is accepted, since running Vault
  needs that image anyway, so the pull warms the cache.

**Security:**
- **Secrets:** `status` and every message print only env **keys** and env file **names**, never
  values.
- **Release integrity:** `github-release` also uploads `SHA256SUMS` for every asset. The README
  (#29) shows a download-and-verify alternative to `curl | bash`.
  - `install.sh` takes the CLI from the `darthjee/vault:<version>` image. Tags are not
    immutable, so it relies on Docker Hub's integrity for that tag.
- Everything under **Runtime privileges & host impact** above applies as well.

### Future work list
`cli-overview.md` carries a **Future work** list of the ideas this epic explicitly pushed out:
- `up --wait`;
- a Homebrew tap;
- Windows support;
- `vault build` / `pack`;
- self-update and uninstall;
- `vault ls`;
- Sysbox in CI;
- remote Docker hosts;
- coloured output.

#29 moves whichever items are still relevant into `AGENTS.md` → Future work, before #30 deletes
the spec.
