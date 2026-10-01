# Automation Plan: Repo scaffolding: VERSION, version scripts, Makefile, lint/test via Docker

Main plan: [plan.md](plan.md)

## Shared contracts

See [plan.md](plan.md#shared-contracts). This plan produces every make target, variable and script listed there.

## Steps

- [01 — VERSION and version scripts](automation/01-version-scripts.md)
- [02 — Lint and test scripts](automation/02-lint-test-scripts.md)
- [03 — Makefile](automation/03-makefile.md)

## CI Checks
- No CI exists yet. Check locally with:
  - `make lint`
  - `make test`
  - `make release`, `make bump-version` and `make check-version-tag` without their variables (each must fail)
  - `make check-version-tag TAG=0.1.0` (must pass) and `make check-version-tag TAG=0.1.1` (must fail)
  - every stub target (each must exit 0)

## Notes
- Host scripts must work on bash 3.2 (macOS), so avoid `mapfile`. Use `find -print0` with `while IFS= read -r -d ''`.
- Avoid `sed -i`, which differs between BSD and GNU. Write to a temp file, then `mv`.
- The make variable `VERSION` is user input only. Never load the `VERSION` file into a make variable with that name.
- Commit scripts with mode 100755.
