# Automation Plan: Guides link check and version line (make test-docs)

Main plan: [plan.md](plan.md)

## Shared contracts

- `docs/guides/vault.md` (by `product-owner`) has exactly one line matching
  `^\*\*Vault version:\*\* [0-9]+\.[0-9]+\.[0-9]+$`, value = `VERSION` (`0.0.1`).
- You provide `scripts/check_guides_links.sh [ROOT]` (default `docs/guides` under the repo
  root): one `<file>: <message>: <link>` line per problem on stderr and exit 1; otherwise
  `test-docs: OK (<n> file(s))` and exit 0, including for an empty or missing root.

## Steps

- [01 — Link-check script](automation/01-link-check-script.md)
- [02 — Make target and CI step](automation/02-make-target-and-ci.md)
- [03 — Guides version line in bump/check scripts](automation/03-version-line.md)
- [04 — Bats tests](automation/04-bats-tests.md)

## CI Checks

- `scripts/`, `Makefile`, `test/scripts/`: `make lint`, `make test`, `make test-docs`
  (CI job: `build-and-test`)
- `.circleci/`: `circleci config validate` (if the CLI is installed)
- Manually: `make bump-version VERSION=0.0.2` then `make check-version-tag TAG=0.0.2` on a
  scratch copy, and `make check-version-tag TAG=0.0.1` on the tree.

## Notes

- No change to existing Make target names or release jobs.
- The script runs on the host (macOS bash 3.2 and the CI ubuntu machine), so avoid bash 4+
  features (associative arrays, `${var,,}`, `mapfile`) and GNU-only flags; prefer one
  POSIX `awk` program for parsing.
