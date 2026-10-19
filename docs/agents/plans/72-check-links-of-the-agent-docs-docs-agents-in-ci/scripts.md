# Scripts Plan: Check links of the agent docs (docs/agents) in CI

Main plan: [plan.md](plan.md)

## Shared contracts

You produce `scripts/check_guides_links.sh [ROOT [BOUND]]` exactly as specified in [plan.md](plan.md#shared-contracts): the `BOUND` default is `ROOT`, `ROOT` must be inside `BOUND`, the new message is `relative link leaves the bound`, and anchors are checked on demand for `.md` targets outside `ROOT`. Output format is unchanged. `automation` calls it as `scripts/check_guides_links.sh docs/agents .`.

## Implementation Steps

### Step 1 — Add the bound to `check_guides_links.sh`

- Parse the optional second argument. Resolve `BOUND` with `cd … && pwd` (default: the resolved `ROOT`). Fail with `test-docs: ROOT must be inside BOUND` (exit 1) when the resolved `ROOT` is not `BOUND` and not under `BOUND/`. Keep the missing/empty `ROOT` early exits.
- Compute `root_prefix`, the path of `ROOT` relative to `BOUND` (empty when equal). In `check_link`, normalise `"$root_prefix/$dir$path"` against `BOUND` instead of `ROOT`, check existence under `BOUND`, and report `relative link leaves the bound` when `normalise` fails.
- Key the parsed/slug cache in `$work_dir` by bound-relative path. Same-page anchors resolve to the file's own bound-relative path.
- When an anchor targets a `.md` file inside `BOUND` that has no `.slugs` entry yet (outside `ROOT`), run `parse_markdown` on it on demand and cache its slugs. Then check the anchor.
- Update the header comment (usage, rules, message wording) and replace the remaining "guides" wording in messages with neutral wording. Keep bash 3.2 / POSIX awk compatibility (no `realpath -m`, no associative arrays, no `mapfile`).

### Step 2 — Bats coverage in `test/scripts/check_guides_links.bats`

- Update the existing "leaving the tree" test to the new message (no bound means the bound is `ROOT`, so it still fails).
- New cases, on a fixture with a `BOUND` dir holding `docs/agents/` and sibling files:
  - a link outside `ROOT` but inside `BOUND` passes (file and directory targets);
  - a link leaving `BOUND` fails with `relative link leaves the bound`;
  - an anchor into a page outside `ROOT` is verified: it passes when present and fails with `missing anchor` when absent;
  - a missing file outside `ROOT` fails with `missing file`;
  - a `ROOT` outside `BOUND` fails with exit 1;
  - only files under `ROOT` are scanned: a broken link in a file outside `ROOT` is not reported, and the OK count counts only `ROOT` files.

## Files to Change

- `scripts/check_guides_links.sh` — optional `BOUND`, bound-relative resolution, on-demand anchor parsing, header and message updates.
- `test/scripts/check_guides_links.bats` — updated message and new bound cases.

## CI Checks

- `scripts/`, `test/scripts/`: `make lint`, `make test`, `make test-docs` (CI job: `build-and-test`)
- Also run `scripts/check_guides_links.sh docs/agents .` locally; it must print `test-docs: OK`.

## Notes

- Must still run on bash 3.2 (macOS). The `test/bash32/` image is available if needed.
