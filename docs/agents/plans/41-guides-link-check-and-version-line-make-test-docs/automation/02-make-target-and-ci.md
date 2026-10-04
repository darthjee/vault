# Make target and CI step

- `Makefile`: add `test-docs` to `.PHONY` and a target
  `test-docs:` → `scripts/check_guides_links.sh`. Do not rename or reorder the existing
  targets' behaviour.
- `.circleci/config.yml`, job `build-and-test`: add a step `name: Check guides links`,
  `command: make test-docs`, right after `Run unit tests` (`make test`).
- `.circleci/config.yml`, job `check-version-tag`: update the step name to mention the guides
  version line (e.g. `Check tag matches VERSION, README, guides and VAULT_VERSION lines`).
  The job name and the workflow stay the same.

## Files to Change

- `Makefile` — new `test-docs` target.
- `.circleci/config.yml` — new `build-and-test` step; `check-version-tag` step name.
