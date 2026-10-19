# Automation Plan: Check links of the agent docs (docs/agents) in CI

Main plan: [plan.md](plan.md)

## Shared contracts

You can rely on `scripts/check_guides_links.sh [ROOT [BOUND]]` from `scripts` (see [plan.md](plan.md#shared-contracts)). Call it as `scripts/check_guides_links.sh docs/agents .` for the agent docs. The no-argument call for the guides is unchanged.

## Implementation Steps

### Step 1 — Wire the agent docs into `make test-docs` and CI

- `Makefile`: make the `test-docs` recipe run both checks, guides first:

  ```make
  test-docs:
  	scripts/check_guides_links.sh
  	scripts/check_guides_links.sh docs/agents .
  ```

- `.circleci/config.yml`: rename the `build-and-test` step "Check guides links" to "Check docs links". The command stays `make test-docs`.

## Files to Change

- `Makefile` — `test-docs` also checks `docs/agents/` bounded to the repo root.
- `.circleci/config.yml` — step renamed to "Check docs links".

## CI Checks

- `Makefile`, `.circleci/`: `make test-docs` (CI job: `build-and-test`)
