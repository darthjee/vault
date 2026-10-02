# Product Owner Plan: CircleCI pipeline for PRs: lint, unit tests, build, smoke test

Main plan: [plan.md](plan.md)

## Shared contracts

- **Job name**: `build-and-test`; **executor**: `machine: image: ubuntu-2404:current`; steps `make lint` → `make test` → `make test-image`.

## Implementation Steps

### Step 1 — Update the CI spec
In `docs/agents/specs/docker-image/ci.md`:
- In **CircleCI principles**, replace "Jobs that run Docker use `machine: true`." with the named image (`machine: image: ubuntu-2404:current`), noting that `machine: true` is deprecated.
- In **PR pipeline**, record that #8 implements the checks as a single `build-and-test` job, run in table order, and that the release pipeline's `build-and-test` (#9) is that same job.
- Adjust the "exact YAML … is left to #8 / #9" line, since the PR-side job name and executor are now decided.

## Files to Change
- `docs/agents/specs/docker-image/ci.md` — record the executor image and the `build-and-test` job.

## Notes
- Leave the release pipeline, credentials and Docker Hub sections untouched (#9).
