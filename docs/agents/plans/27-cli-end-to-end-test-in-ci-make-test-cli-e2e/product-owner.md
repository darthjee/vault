# Product Owner Plan: CLI end-to-end test in CI (make test-cli-e2e)

Main plan: [plan.md](plan.md)

## Shared contracts

- You can rely on `automation` producing `make test-cli-e2e` (depends on `build-image`), backed by
  `scripts/test_cli_e2e.sh`, using `IMAGE`/`SMOKE_TIMEOUT`. It runs in CircleCI `build-and-test`
  after `make test-image`.

## Implementation Steps

### Step 1 — Document the new target and test layer
Describe `test-cli-e2e` wherever `test-image` / `test_image.sh` is documented today. Keep it short
and match the surrounding style:
- `docs/agents/architecture.md`: add an "End-to-end" row to the testing table (around line 89). It
  covers `make test-cli-e2e` and `scripts/test_cli_e2e.sh`, which runs the real `build/vault`
  `up`/`status`/`compose ps`/`down` against the fixture (`--runtime=privileged`, a free localhost
  port, a unique name, volume kept after `down`), then `install.sh` from the local image into a
  temp `HOME`, with cleanup always run.
- `docs/agents/folder-structure.md`: add `test_cli_e2e.sh` to the `scripts/` list (line 10 and the
  scripts section) and a `test-cli-e2e` row to the Make targets table ("Depends on `build-image`,
  then runs `scripts/test_cli_e2e.sh`").
- `docs/agents/contributing.md`: add `make test-cli-e2e` to the checks for `cli/`, `install.sh`,
  `Dockerfile` and `source/` changes (around line 52).

### Step 2 — Update AGENTS.md CI summary
In `AGENTS.md`, update the `build-and-test` description (around lines 82–83) and the Makefile
targets list (around line 92) to include `make test-cli-e2e`, run after `make test-image`.

## Files to Change
- `docs/agents/architecture.md` — testing table row.
- `docs/agents/folder-structure.md` — scripts list and Make targets table.
- `docs/agents/contributing.md` — checks table.
- `AGENTS.md` — CI summary and targets list.

## Notes
- `AGENTS.md` is a root file (architect's scope). The edit is documentation-only and mirrors the
  docs/agents changes, so product-owner does it as part of this step.
- The specs (`docs/agents/specs/cli-ci.md`, `cli-tooling.md`) already describe `test-cli-e2e`; leave
  them unchanged unless something they say contradicts the implementation.
