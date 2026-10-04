# Folder Structure

## Project Root

| Directory / File | Description |
|-----------------|-------------|
| `Dockerfile` | Builds the Vault image (`FROM docker:${DOCKER_VERSION}-dind`, adds bash, installs `source/`, the CLI bundle `build/vault` as `/usr/local/bin/vault` and the completions, `EXPOSE 80`, `VOLUME /var/lib/docker`, `WORKDIR /vault`). |
| `source/` | Files installed into the image: `bin/entrypoint.sh` (the container entrypoint), `bin/install.sh` (the `vault-install` entry) and `lib/*.sh` (function libraries). Owner `dev`. See [source/](#source). |
| `cli/` | The host-side `vault` CLI: `bin/vault`, `lib/*.sh`, `completion/vault.bash`, `completion/_vault`. Owner `cli`. See [cli/](#cli). |
| `install.sh` | The `curl \| bash` installer of the CLI (published as a release asset). Owner `cli`. |
| `test/` | Bats tests and fixtures. See [test/](#test). |
| `scripts/` | Repo scripts for development and CI: `bump_version.sh`, `check_tag_version.sh`, `bundle_cli.sh`, `lint.sh`, `test.sh`, `test_image.sh`, `test_cli_e2e.sh`, `release.sh`, `github_release.sh`, `ci/`. See [scripts/](#scripts). |
| `build/` | Generated, git-ignored: `build/vault` (the CLI bundle) and `build/github-release/` (release assets staged by `github_release.sh`). Owner `automation`. |
| `.circleci/` | CI and release pipeline. |
| `Makefile` | The only entry point for developers and CI. See [Makefile](#makefile). |
| `VERSION` | Current version; checked against the release tag. |
| `DOCKERHUB_DESCRIPTION.md` | Docker Hub page content. |
| `README.md`, `AGENTS.md`, `LICENSE` | User documentation, project instructions for agents, license. |
| `docs/agents/` | Agent documentation, issues (`issues/`), implementation plans (`plans/`) and temporary per-epic specs (`specs/`, see [specs.md](specs.md)). |
| `docs/guides/` | Portable user guides (`vault.md` + `vault/*.md`), copied by hand into consumer repos. Owner `product-owner`. Does not exist yet; #42 creates it (see the [guides spec](specs/guides-overview.md)). |
| `.github/` | PR template, commit message template, Copilot pointer. |
| `.claude/` | Claude agents, check scripts and configuration. |

## source/

| Subdirectory | Description |
|--------------|-------------|
| `bin/` | `entrypoint.sh` — the container entrypoint (`vault-entrypoint`); the only file of the runtime flow that reads environment variables. `install.sh` — the in-image install entry (`vault-install`), run by the root `install.sh` to copy the CLI and completions into a bind-mounted `/install`. |
| `lib/` | Function libraries: `preflight.sh`, `dockerd.sh`, `images.sh`, `compose.sh`, `signals.sh` (sourced by the entrypoint) and `install.sh` (`install_copy`, sourced by `bin/install.sh`). |

## cli/

| Path | Description |
|------|-------------|
| `bin/vault` | Entry point: dispatches the commands and resolves options, `.vaultrc`, name, runtime and `docker run` arguments. The only script that reads the environment, `PWD`, `DOCKER_HOST` and `.vaultrc`. Its `# BEGIN LIBS` / `# END LIBS` block sources the libraries and is replaced by their content in the bundle. |
| `lib/output.sh` | `vault: error/warning/hint:` diagnostics on stderr. |
| `lib/usage.sh` | The usage text. |
| `lib/docker.sh` | `docker_run_cmd`: the single entry point for docker calls (stubbed in tests). |
| `lib/args.sh` | Option, `[dir]` and passthrough parsing into `ARGS_*`. |
| `lib/naming.sh` | Instance name, `vault-<name>` container, `vault-<name>-data` volume. |
| `lib/config.sh` | `.vaultrc` parsing (from stdin), precedence merge, `.vault.env` placement. |
| `lib/guardrails.sh` | Refuses Docker socket mounts and ports 2375 / 2376. |
| `lib/runtime.sh` | `docker` on `PATH`, `docker info` probe, rootless check, runtime selection. |
| `lib/container.sh` | The `docker run` argument list of `up` and `run`. |
| `lib/instance.sh` | Instance state, TTY flags, status output, `docker run` result attribution. |
| `completion/vault.bash` | bash completion (bash 3.2+). Not bundled; installed next to the CLI. |
| `completion/_vault` | zsh completion. Not bundled; installed next to the CLI. |

`scripts/bundle_cli.sh` concatenates the libraries, in a fixed order, into the single
executable `build/vault`.

## test/

| Path | Description | Owner |
|------|-------------|-------|
| `lib/` | Bats tests for `source/lib/`. | `dev` |
| `fixture/` | `docker-compose.yml`, the stack used by the smoke and CLI end-to-end tests. | `dev` |
| `cli/` | Bats tests for the CLI (`cli/bin/vault`, `cli/lib/`, completion); `helpers/` holds the docker stub and CLI loaders. | `cli` |
| `install/` | Bats tests for the root `install.sh`; `helpers/` holds its stub. | `cli` |
| `bash32/` | `Dockerfile` of the bash 3.2 bats image (`BASH32_TEST_IMAGE`) that also runs `test/cli/` and `test/install/`. | `automation` |
| `scripts/` | Bats tests for repo scripts such as `scripts/github_release.sh`, with a stub `gh` in `helpers/`. | `automation` |

## scripts/

- **Make is the only entry point.** Developers and CI call make targets, never scripts directly.
- A recipe longer than one line moves to `scripts/*.sh`.
- CI-only steps live in `scripts/ci/`:
  - `docker_login.sh` — `docker login` to Docker Hub.
  - `setup_buildx.sh` — QEMU / buildx setup for multi-platform builds.
  - `update_description.sh` — fetches `docker_hub.sh` (pinned) and pushes `DOCKERHUB_DESCRIPTION.md`.
- Build script: `bundle_cli.sh` (builds `build/vault` from `cli/bin/vault` and `cli/lib/*.sh`).
- Release scripts: `release.sh` (multi-arch build and push), `github_release.sh` (GitHub release of the
  CLI assets with `gh`).
- Test scripts: `test.sh` (bats), `test_image.sh` (smoke test), `test_cli_e2e.sh` (CLI end-to-end test).
- Everything under `scripts/` is shellchecked by `make lint`.

## Makefile

| Target | Behaviour |
|--------|-----------|
| `bundle-cli` | Builds the CLI bundle `build/vault` (`scripts/bundle_cli.sh`). |
| `build-image` | Depends on `bundle-cli`, then `docker build` the image as `IMAGE`, passing `--build-arg DOCKER_VERSION` when set. |
| `lint` | shellcheck over `source/`, `scripts/`, `cli/` and `test/`, plus `cli/bin/vault`, `cli/completion/vault.bash` and `install.sh` (`scripts/lint.sh`). |
| `test` | Builds the CLI bundle, then bats over `test/lib/`, `test/cli/`, `test/install/` and `test/scripts/` on `BATS_IMAGE`, `test/cli/` and `test/install/` again on the bash 3.2 image, and `zsh -n cli/completion/_vault` (`scripts/test.sh`). |
| `test-image` | Depends on `build-image`, then runs the smoke test (`scripts/test_image.sh`). |
| `test-cli-e2e` | Depends on `build-image`, then runs `scripts/test_cli_e2e.sh` (CLI end-to-end test). |
| `bump-version VERSION=X.Y.Z` | Updates `VERSION`, the README version line and the `VAULT_VERSION` lines of `cli/bin/vault` and `install.sh` (`scripts/bump_version.sh`). |
| `check-version-tag TAG=X.Y.Z` | Fails unless the tag matches `VERSION`, the README and the `VAULT_VERSION` lines (`scripts/check_tag_version.sh`). |
| `release TAG=x` | Depends on `bundle-cli`; multi-arch build and push (`scripts/release.sh`). Fails fast without `TAG`. |
| `github-release TAG=X.Y.Z` | Builds the CLI bundle and `SHA256SUMS`, creates (or reuses) the GitHub release and uploads the assets (`scripts/github_release.sh`). Fails fast without `TAG`. |
| `update-description` | Pushes `DOCKERHUB_DESCRIPTION.md` to Docker Hub (`scripts/ci/update_description.sh`). |
| `ci-release-setup` | CI-only: buildx setup and Docker Hub login. |

| Variable | Default | Purpose |
|----------|---------|---------|
| `SHELLCHECK_IMAGE` | `koalaman/shellcheck:v0.11.0` | Image used by `make lint`. |
| `BATS_IMAGE` | `bats/bats:1.14.0` | Image used by `make test`. |
| `BASH32_TEST_IMAGE` | `vault-bash32-test:local` | bash 3.2 bats image built from `test/bash32/` by `make test`. |
| `ZSH_IMAGE` | `zshusers/zsh:5.9` | Image running `zsh -n` on the zsh completion in `make test`. |
| `IMAGE` | `darthjee/vault:dev` | Tag built by `build-image` and tested by `test-image` and `test-cli-e2e`. |
| `SMOKE_TIMEOUT` | `120` | Seconds `test-image` and `test-cli-e2e` wait for the stack to answer. |
| `RELEASE_IMAGE` | `darthjee/vault` | Repository `release` pushes to. |
| `PUSH` | `true` | Whether `release` pushes (set `false` to build only). |
| `DOCKER_VERSION` | unset (Dockerfile default) | Base image version passed as a build arg. |
