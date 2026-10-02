# Plan: CircleCI pipeline for PRs: lint, unit tests, build, smoke test

Issue: [8-circleci-pipeline-for-prs-lint-unit-tests-build-smoke-test.md](../../issues/8-circleci-pipeline-for-prs-lint-unit-tests-build-smoke-test.md)

## Overview
Add `.circleci/config.yml` with a single `build-and-test` job on a `ubuntu-2404:current` machine executor. It runs `make lint`, `make test` and `make test-image` on every branch and PR. Then update the spec, `AGENTS.md` and the automation agent definition so they reference the named machine image instead of the deprecated `machine: true`.

## Agents involved

- [automation](automation.md)
- [product-owner](product-owner.md)
- [architect](architect.md)

## Shared contracts

- **Config file**: `.circleci/config.yml`, `version: 2.1`.
- **Job name**: `build-and-test`. #9 adds its release workflow on top of this job and reuses it unchanged.
- **Executor**: `machine: image: ubuntu-2404:current`. The deprecated `machine: true` form is not used anywhere.
- **Job steps, in order**: `checkout` → `make lint` → `make test` → `make test-image` (`test-image` depends on `build-image`, so the image is built there).
- **Workflow**: a single workflow (e.g. `build-and-test`) that runs the `build-and-test` job on every branch and PR, with no filters and no contexts.
- **Credentials**: none. No `context:` is attached to the job.
