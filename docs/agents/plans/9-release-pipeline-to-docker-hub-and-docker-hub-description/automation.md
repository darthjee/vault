# Automation Plan: Release pipeline to Docker Hub and Docker Hub description

Main plan: [plan.md](plan.md)

## Shared contracts

- Context `docker-hub` provides `DOCKER_HUB_USERNAME` and `DOCKER_HUB_PASSWORD` to `build-and-release` and `update-description` only.
- `docker_hub.sh` is fetched from `darthjee/docker` at commit `91b11fb949bb0f71670e390fdc97df831c46af70`, path `scripts/0.9.0/home/sbin/docker_hub.sh`. Its sha256 must equal `cd0cb716f77443a2a806a85599adf270e4ab3e60a74411bafe023f6b3fd1c66a`.
- Release tags match `/^[0-9]+\.[0-9]+\.[0-9]+$/`. The release pushes `darthjee/vault:X.Y.Z` and `:latest` for `linux/amd64,linux/arm64`.

## Steps

- [01 — CI wrapper scripts](automation/01-ci-wrapper-scripts.md)
- [02 — Release script and Makefile targets](automation/02-release-and-makefile.md)
- [03 — Docker Hub description](automation/03-dockerhub-description.md)
- [04 — CircleCI release workflow](automation/04-circleci-release-workflow.md)

## CI Checks
- `scripts/`, `Makefile`: `make lint` (CI job: `build-and-test`)
- `.circleci/`: `circleci config validate`
- Manual checks:
  - `make release` with no `TAG` exits non-zero before any build.
  - `make release TAG=0.1.0 PUSH=false` builds both platforms locally without pushing. It needs QEMU/binfmt on the host, for example via `make ci-release-setup` without credentials, or Docker Desktop.

## Notes
- **No tag is pushed.** Do not run `make release` with `PUSH=true`, and do not run `make update-description` against Docker Hub.
- `docker_hub.sh` runs `curl` without `--fail`, so a rejected login or PATCH still exits 0. The wrapper checks that both credentials are set before it runs. It cannot detect an API error without patching the upstream script, which is out of scope. Mention this in the PR.
- `docker_hub.sh` needs `bash`, `curl` and `jq`. The `ubuntu-2404:current` machine image ships all three.
- `ci-release-setup` is a CI-only target. It is not in the spec's target table, so mention it in the PR so #10 can sync the docs.
