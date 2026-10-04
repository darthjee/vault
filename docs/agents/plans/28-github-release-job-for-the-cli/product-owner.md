# Product Owner Plan: GitHub release job for the CLI

Main plan: [plan.md](plan.md)

## Shared contracts

Record what `automation` implements: `gh` CLI from the CircleCI machine image; `GITHUB_TOKEN`
(exported as `GH_TOKEN`) from context `github`; a published release marked Latest, with generated
notes; on re-run, the existing release is kept and its assets are re-uploaded with `--clobber`; the
new `test/scripts/` suite runs on `BATS_IMAGE` only.

## Implementation Steps

### Step 1 — Settle open point 9 and the tooling in the specs
- `cli-overview.md`: open point 9 → **Settled:** keep the existing release (notes untouched) and
  re-upload all assets with `--clobber`. `#28 (settled)`.
- `cli-ci.md` → `github-release`: replace "Executor and tooling (`gh`, `curl`) are left to #28"
  with the machine executor + `gh` from the image. Note published + `--latest` + `--generate-notes`,
  and the re-run behaviour. Replace "open point 9, settled by #28" with the settled wording.
- `cli-tooling.md` → lint/test coverage table: add `test/scripts/` (on `BATS_IMAGE` only).

### Step 2 — Folder structure
- `docs/agents/folder-structure.md`: add `scripts/github_release.sh` and `test/scripts/` (owner
  `automation`), if that doc lists files at that level.

## Files to Change
- `docs/agents/specs/cli-overview.md` — open point 9 settled.
- `docs/agents/specs/cli-ci.md` — tooling, publish mode, re-run behaviour.
- `docs/agents/specs/cli-tooling.md` — test coverage table.
- `docs/agents/folder-structure.md` — new paths, if applicable.

## Notes
- Only document. Flag to the architect anything in `AGENTS.md` that contradicts this (e.g. the release
  flow diagram missing `github-release`).
