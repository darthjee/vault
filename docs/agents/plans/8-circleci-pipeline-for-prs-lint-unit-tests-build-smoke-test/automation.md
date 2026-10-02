# Automation Plan: CircleCI pipeline for PRs: lint, unit tests, build, smoke test

Main plan: [plan.md](plan.md)

## Shared contracts

- **Config file**: `.circleci/config.yml`, `version: 2.1`.
- **Job name**: `build-and-test`. #9 adds its release workflow on top of this job and reuses it unchanged.
- **Executor**: `machine: image: ubuntu-2404:current`. The deprecated `machine: true` form is not used anywhere.
- **Job steps, in order**: `checkout` → `make lint` → `make test` → `make test-image` (`test-image` depends on `build-image`, so the image is built there).
- **Workflow**: a single workflow (e.g. `build-and-test`) that runs the `build-and-test` job on every branch and PR, with no filters and no contexts.
- **Credentials**: none. No `context:` is attached to the job.

## Implementation Steps

### Step 1 — Add `.circleci/config.yml`
Create the config with `version: 2.1` and one job, `build-and-test`, on `machine: image: ubuntu-2404:current`. Its steps are `checkout`, then `make lint`, `make test` and `make test-image`, each as a separate `run` step with a readable `name` so failures are easy to spot. Add one workflow that runs the job with no branch/tag filters and no context. Keep the YAML thin: no inline shell logic beyond `make <target>`. If a step ever needs more, it goes into `scripts/ci/*.sh` (not needed here). Do not add release jobs or tag filters, since those belong to #9.

### Step 2 — Validate
Run `circleci config validate` if the CLI is installed; otherwise state in the PR that it was skipped. Run `make lint` and `make test` locally to confirm the targets the job calls still pass. The final check is a green pipeline on the PR, which needs the CircleCI project to exist. That is a manual maintainer prerequisite: flag it in the PR if the pipeline does not trigger.

## Files to Change
- `.circleci/config.yml` — new: the PR pipeline (`build-and-test` job + workflow).

## CI Checks
- `.circleci/`: `circleci config validate` (if the CLI is installed)
- `scripts/`: `make lint` (CI job: `build-and-test`)

## Notes
- `make test-image` uses `--privileged` and `curl` on the host. The ubuntu machine image provides both, plus Docker.
- No caching is needed: the shellcheck/bats images are small and the Vault image builds from `docker:dind`.
