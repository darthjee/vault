# Issue: Release: github-release job fails with "gh not found in PATH"

## Description
The CircleCI `release` workflow's `github-release` job cannot publish the CLI as a GitHub release, because the GitHub CLI (`gh`) is not installed on its executor.

## Problem
In the `release` workflow, job `github-release`, step "Create GitHub release and upload CLI assets" fails for tag 0.1.0:

```
scripts/github_release.sh 0.1.0
github-release: gh not found in PATH
make: *** [Makefile:51: github-release] Error 1

Exited with code exit status 2
```

The job runs on the `ubuntu-2404:current` machine executor, which does not ship `gh`, and nothing in the job installs it. `scripts/github_release.sh` checks for `gh` and needs it for `gh release view/create/upload`.

## Expected Behavior
On a release tag, the `github-release` job installs `gh` and then creates the GitHub release and uploads the CLI assets (`vault`, `install.sh`, `vault.bash`, `_vault`, `SHA256SUMS`) successfully.

## Solution
Install `gh` in the `github-release` job before `make github-release`, from GitHub's official apt repository (cli.github.com):

- New CI-only script `scripts/ci/install_gh.sh` (same style as `scripts/ci/setup_buildx.sh`): do nothing if `gh` is already on PATH; otherwise add the cli.github.com keyring and apt source and run `sudo apt-get install -y gh`; print `gh --version`.
- New Makefile target `ci-github-release-setup` (mirroring `ci-release-setup`) that runs the script; add it to `.PHONY`.
- `.circleci/config.yml`: add an "Install GitHub CLI" step (`make ci-github-release-setup`) to the `github-release` job, before the release step.
- Docs: list the new script and target where `ci-release-setup`/`setup_buildx.sh` are listed — `AGENTS.md` (CI job description and Makefile targets) and `docs/agents/folder-structure.md`.

### Out of scope
- Changing `scripts/github_release.sh` behaviour.
- Pinning a `gh` version (apt installs the latest).

### Testing
- `make lint` (shellcheck on the new script).
- Re-run the `github-release` job for tag 0.1.0 — the script is idempotent (an existing release is kept, assets are replaced with `--clobber`).

## Benefits
The release workflow completes end to end, and every release publishes the CLI assets that `install.sh` downloads.
