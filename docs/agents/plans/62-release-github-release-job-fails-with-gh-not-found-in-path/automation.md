# Automation Plan: Release: github-release job fails with "gh not found in PATH"

Main plan: [plan.md](plan.md)

## Overview
Add `scripts/ci/install_gh.sh` (installs `gh` from cli.github.com via apt, no-op when already installed), a CI-only make target `ci-github-release-setup` that runs it, and a CircleCI step calling that target before `make github-release`. Update the docs that wrongly say `gh` comes from the machine image.

## Context
The `github-release` job runs on `machine: image: ubuntu-2404:current`, which does not ship `gh`. `scripts/github_release.sh` exits with `github-release: gh not found in PATH` (tag 0.1.0). The repo convention (AGENTS.md) is that CircleCI YAML only calls make targets and CI-only wrappers live in `scripts/ci/` — see `scripts/ci/setup_buildx.sh` and the `ci-release-setup` target for the pattern to mirror.

## Steps

- [01 — Add the install script](automation/01-add-install-script.md)
- [02 — Wire the make target and CircleCI step](automation/02-wire-make-and-circleci.md)
- [03 — Update the docs](automation/03-update-docs.md)

## CI Checks
- `scripts/`: `make lint` (CI job: `build-and-test`)
- `.circleci/config.yml`, `Makefile`: only exercised by the `release` workflow on an `X.Y.Z` tag; verify by re-running the `github-release` job for tag 0.1.0 after merge.

## Notes
- `gh` is not pinned (apt installs the latest), by decision in the issue.
- Re-running `github-release` for 0.1.0 is safe: `github_release.sh` keeps an existing release and uploads assets with `--clobber`.
- No bats test for `install_gh.sh`: like the other `scripts/ci/` wrappers it is untested CI glue (it needs sudo/apt); shellcheck covers it.
