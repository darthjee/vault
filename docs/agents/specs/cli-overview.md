# CLI Spec: Overview

Spec for epic #20 (Vault CLI). Written by #21.

| File | Contents |
|------|----------|
| [cli-overview.md](cli-overview.md) | Goals, principles, paths, ownership, compatibility, sub-issue map, open points, future work. |
| [cli-commands.md](cli-commands.md) | Commands and flags, naming, runtime selection, privilege model, messages, exit codes, edge cases. |
| [cli-config.md](cli-config.md) | `.vaultrc`, `.vault.env`, precedence, parsing errors. |
| [cli-install.md](cli-install.md) | What the image ships, the install entry, `install.sh`, completion locations. |
| [cli-tooling.md](cli-tooling.md) | Version line, bundling rule, Make targets, lint/test coverage, testing strategy. |
| [cli-ci.md](cli-ci.md) | PR pipeline, `test-cli-e2e`, the `github-release` job, released assets. |

## Status of this document

- **Working document.** While epic #20 is open, `docs/agents/specs/*.md` overrides the other
  agent docs (`AGENTS.md`, `architecture.md`, `flow.md`, …) where they conflict.
- **Source of truth.** Once merged, the spec wins over the body of epic #20. The epic body is
  not kept in sync.
- **Deviations.** A later PR that deviates from the spec updates the spec in the same PR. Tests
  assert the wording written here, so a wording change is a spec change.
- **Split changes.** Whoever adds, merges or renumbers sub-issues updates the
  [sub-issue map](#sub-issue-map).
- **Lifetime.** #29 moves what stays relevant into the README and the agent docs; #30 deletes
  every file in this folder (and the folder, if empty).

## Goals

- A host-side `vault` command that runs Vault containers, so users don't hand-craft
  `docker run`.
- It handles:
  - instance naming;
  - the `/vault` and `/var/lib/docker` mounts;
  - ports, env vars and extra mounts;
  - runtime selection: Sysbox when available, otherwise `--privileged` with a visible warning.
- `vault compose <args>` runs compose against the inner stack of a running instance.
- The CLI is versioned with the image, shipped inside it, and attached to the GitHub release.
- It installs with `curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash`.

## Principles

- **Bash 3.2+.** It runs on stock macOS `/bin/bash` 3.2.57. No associative arrays, `mapfile`,
  `${var,,}`, `declare -n`, `[[ -v ]]` or any other bash 4+ feature. Shebang
  `#!/usr/bin/env bash`.
- **Config is data.** `.vaultrc` is parsed line by line and never `source`d; `.vault.env` is
  only handed to `docker run --env-file`.
- **Never escalate privileges silently.**
  - Sysbox is preferred.
  - `--privileged` is used only when Sysbox is not detected, and then with a warning.
  - A forced runtime is never swapped, and a failed Sysbox run never falls back to
    `--privileged`.
- **Privilege model (summary).** The CLI runs as the current user and never calls `sudo`. It
  refuses rootless daemons, host Docker socket mounts and publishing container ports 2375/2376.
  Full model: [cli-commands.md → Privilege model](cli-commands.md#privilege-model).
- **Secrets stay out of output.** Only env **keys** and env file **names** are printed.
- **Platforms:** Linux and macOS. Windows (including WSL) is neither tested nor promised.
- **Code style:** as in [contributing.md](../contributing.md) (libraries only define functions,
  prefixed by module; only `cli/bin/vault` reads the environment and `.vaultrc`; `docker` is
  wrapped so bats can stub it).

## Paths

### Source layout

| Path | Contents |
|------|----------|
| `cli/bin/vault` | CLI main: the only CLI file that runs logic and reads the environment and `.vaultrc`. Holds the `VAULT_VERSION="X.Y.Z"` line and the `# BEGIN LIBS` … `# END LIBS` block. |
| `cli/lib/*.sh` | CLI libraries (functions only, `# shellcheck shell=bash` instead of a shebang). #22 ships `output.sh` (`output_error`, `output_warning`, `output_hint`) and `usage.sh` (`usage_print`); #23 may add more. |
| `cli/completion/vault.bash` | bash completion. |
| `cli/completion/_vault` | zsh completion. |
| `install.sh` | `curl \| bash` installer at the repo root; also a release asset. |
| `source/bin/install.sh` | In-image install entry (installed as `vault-install`). |
| `test/cli/*.bats` | CLI tests. |
| `test/install/*.bats` | Tests for `install.sh` and the install entry. |
| `test/bash32/Dockerfile` | bash 3.2 test image (`FROM bash:3.2` + pinned bats-core). |
| `scripts/bundle_cli.sh` | Builds the bundle. |
| `scripts/test_cli_e2e.sh` | End-to-end test. |
| `scripts/github_release.sh` | Creates the GitHub release. |

### Bundle

- `build/vault`: the single executable built by `make bundle-cli`. `build/` is git-ignored
  (added in #22). See [cli-tooling.md → Bundling rule](cli-tooling.md#bundling-rule).

### In-image paths

| Path | Contents |
|------|----------|
| `/usr/local/bin/vault` | The bundled CLI (`build/vault`). |
| `/usr/local/bin/vault-install` | The install entry (from `source/bin/install.sh`). |
| `/usr/local/share/vault/completion/vault.bash` | bash completion. |
| `/usr/local/share/vault/completion/_vault` | zsh completion. |
| `/install` | Bind-mount target that the install entry copies into. |

Details: [cli-install.md](cli-install.md).

## Agent ownership

| Agent | Owns |
|-------|------|
| `cli` | `cli/bin/vault`, `cli/lib/*.sh`, `cli/completion/*`, root `install.sh`, `test/cli/`, `test/install/` |
| `dev` | `Dockerfile`, `source/` (including `source/bin/install.sh`, the in-image install entry), `test/lib/`, `test/fixture/` and the image tests |
| `automation` | `.circleci/`, `Makefile`, `scripts/` (incl. `scripts/bundle_cli.sh`, `scripts/test_cli_e2e.sh`, `scripts/github_release.sh`), `VERSION`, `DOCKERHUB_DESCRIPTION.md`, `test/bash32/`, `build/` (git-ignored bundle output) |
| `product-owner` | `docs/agents/` (including `docs/agents/specs/`) |
| `architect` | root-level files except `install.sh`, `.github/`, `.claude/` |

- `install.sh` at the root is an explicit exception to the architect's root-level ownership.
- The `.gitignore` entry for `build/` is added by #22 (`automation` requests it from the
  architect if needed).
- An agent that needs a change outside its paths reports it to the owner.

## Backward compatibility

Every sub-issue of #20 is held to these guarantees:

- **The image's default behaviour is unchanged:** `docker run darthjee/vault` still runs
  `docker compose up`, with the same passthrough args, env vars, exit codes and signal handling.
  The image only gains files (the CLI, `vault-install`, the completions).
- **Plain `docker run` keeps working** as documented in the README today. The CLI is optional.
- **Make targets keep their names.** `make test` is extended (it adds the bash 3.2 run), not
  renamed. New targets are added alongside.
- **The release chain keeps its jobs.** `github-release` is added after `build-and-release`; a
  failure there never unpublishes the Docker image.
- **`VERSION` stays the single version source.** The image and the CLI share it.

## Sub-issue map

| Sub-issue | Agents | Spec sections |
|-----------|--------|---------------|
| #21 Spec and `cli` agent | `product-owner`, `architect` | This folder; ownership above. |
| #22 Scaffolding and tooling | `automation`, `cli` | [cli-tooling.md](cli-tooling.md): version line, bundling rule, Make targets, lint/test coverage; `vault version` / `vault help` in [cli-commands.md](cli-commands.md#commands). |
| #23 CLI core | `cli` | [cli-commands.md](cli-commands.md): syntax and flags, instance naming, runtime selection, privilege model, guardrails, diagnostics and exit codes; [cli-config.md](cli-config.md). |
| #24 CLI commands | `cli` | [cli-commands.md](cli-commands.md): commands, `status` output, messages, edge cases, performance. |
| #25 Shell completion | `cli` | [cli-commands.md → Shell completion](cli-commands.md#shell-completion); completion paths in [cli-install.md](cli-install.md). |
| #26 Install path | `dev`, `cli`, `automation` | [cli-install.md](cli-install.md); edge case 13 in [cli-commands.md](cli-commands.md#edge-cases); wiring `bundle-cli` into the image targets and making `install.sh` required in the version scripts ([cli-tooling.md](cli-tooling.md)). |
| #27 End-to-end test in CI | `automation` | [cli-tooling.md → Testing strategy](cli-tooling.md#testing-strategy); [cli-ci.md → PR pipeline](cli-ci.md#pr-pipeline). |
| #28 GitHub release job | `automation` | [cli-ci.md → Release pipeline](cli-ci.md#release-pipeline). |
| #29 User docs and agent docs sync | `product-owner`, `automation` | [Future work](#future-work); [cli-commands.md → Notes for the README](cli-commands.md#notes-for-the-readme). |
| #30 Remove the spec | `product-owner` | Deletes this folder and every reference to it. |

## Open points

Each open point names the sub-issue that settles it, and that sub-issue updates the spec. None
blocks #21.

| # | Open point | Proposed default | Settled by |
|---|------------|------------------|------------|
| 1 | How `vault run` tells `[dir]` apart from the first compose argument (`vault run config`). | The first positional is `[dir]` only when it names an existing directory; `--` forces the end of CLI options. | #23 |
| 2 | Whether `vault run` may start while `vault-<name>` is running (both would share `vault-<name>-data`). | Refuse with an error and exit 1. | #24 |
| 3 | Whether `vault run` adds `-i` / `-t` when attached to a terminal. | `-t` when stdout is a TTY, `-i` when stdin is a TTY. | #24 |
| 4 | Exact `status` layout (fields are fixed). | The draft in [cli-commands.md → status](cli-commands.md#status-output). | #24 |
| 5 | How commands that skip `docker info` (`down`, `logs`, `status`, `compose`) tell a missing instance from an unreachable daemon. | Classify `docker inspect`'s failure: "No such object" → missing instance; anything else → `cannot reach the Docker daemon`. | #24 |
| 6 | How a failed `docker run` is attributed to Sysbox vs. a busy port. | Docker's error mentioning `port is already allocated` / `address already in use` → port hint; any other start failure under `sysbox-runc` → Sysbox hint. | #24 |
| 7 | Whether `test/lib/` (the in-image entrypoint tests) also runs under bash 3.2. | **Settled: No.** Only `test/cli/` and `test/install/` run under bash 3.2; `test/lib/` runs on `BATS_IMAGE` only (the image's own bash is current). | #22 (settled) |
| 8 | Which image runs the `zsh -n` syntax check of `_vault`. | A pinned zsh image, called from `make test`. | #25 (with `automation`) |
| 9 | `github-release` behaviour when the release already exists (job re-run). | Re-upload the assets, replacing existing ones. | #28 |
| 10 | Whether `install.sh`'s staging dir needs to avoid `$TMPDIR` for Docker Desktop shared paths. | Use `mktemp -d` (Docker Desktop shares `/tmp` and `/var/folders` by default). | #26 |

## Future work

Pushed out of epic #20 on purpose. #29 moves the items still relevant into `AGENTS.md` →
Future work before #30 deletes the spec.

- `vault up --wait` (block until the inner stack is up).
- A Homebrew tap.
- Windows support.
- `vault build` / `vault pack` (an image builder).
- Self-update and uninstall commands.
- `vault ls` (list every instance).
- Sysbox in CI.
- Special handling of remote Docker hosts (`DOCKER_HOST`, contexts).
- Coloured output.
