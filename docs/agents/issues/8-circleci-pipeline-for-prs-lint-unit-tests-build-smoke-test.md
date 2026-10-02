# Issue: CircleCI pipeline for PRs: lint, unit tests, build, smoke test

## Description
Part of epic #2. Add a CircleCI pipeline that validates every branch and PR of the Vault image, following [`docs/agents/specs/docker-image/ci.md`](../specs/docker-image/ci.md) (PR pipeline section).

Depends on the repo scaffolding (#4) and smoke test (#7) sub-issues. Both are merged: `make lint`, `make test`, `make build-image` and `make test-image` already exist.

## Problem
The repo has no `.circleci/` folder. Nothing checks PRs automatically, so lint, bats and smoke-test regressions show up only when someone runs `make` by hand.

## Expected Behavior
- Every push to any branch, and every PR, runs:

  | Check | Make target |
  |-------|-------------|
  | Lint (shellcheck) | `make lint` |
  | Unit tests (bats) | `make test` |
  | Image build | `make build-image` |
  | Smoke test (`--privileged`, amd64 only) | `make test-image` |
- A failing check fails the pipeline and the PR status.
- No credentials or contexts are attached to these jobs.

## Solution
- Add `.circleci/config.yml` (owned by `automation`).
- The YAML only sets up executors and filters and **calls make targets**. Any extra logic goes to `scripts/*.sh` / `scripts/ci/*.sh`, never inline in the YAML.
- A **single job, `build-and-test`**, runs `make lint` → `make test` → `make test-image` in order (`test-image` already depends on `build-image`). #9's release pipeline reuses this same job unchanged.
- The executor is `machine: image: ubuntu-2404:current`, not the deprecated `machine: true`. It is still a full VM, so `--privileged` works, and `make lint` / `make test` can run shellcheck and bats via `docker run`.
- Update `docs/agents/specs/docker-image/ci.md` (and the `machine: true` mention in `AGENTS.md`) to record the executor image and the `build-and-test` job.
- No branch or tag filters beyond the defaults (runs on all branches).

### Out of scope
- Release jobs, tag filters (`X.Y.Z`), buildx/QEMU, Docker Hub credentials/context, and `update-description`. These belong to #9.
- Creating the CircleCI project for the repo. A maintainer does this manually (ci.md → Manual prerequisites).

### Done when
- `circleci config validate` passes (if the CLI is available).
- The pipeline is green on this issue's PR.

## Benefits
- Every PR gets lint, unit and smoke-test feedback automatically.
- #9's release pipeline can reuse the `build-and-test` job as-is.
