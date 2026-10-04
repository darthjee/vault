# Cover the script with bats

Add `test/scripts/github_release.bats`, with a stub `gh` on `PATH` (a small script in
`test/scripts/helpers/` that logs its argv to a file under `$BATS_TEST_TMPDIR` and exits according to
env vars, e.g. `GH_STUB_VIEW_STATUS`). Run the script against a temp copy of the repo, or point it at
`ROOT` read-only, writing only to `build/`. Prefer copying the needed files (`scripts/`, `cli/`,
`install.sh`) into `$BATS_TEST_TMPDIR`, because `scripts/test.sh` mounts the repo read-only.

Cases:
- no tag → usage, exit 1, `gh` never called;
- no `GITHUB_TOKEN` → exit 1, `gh` never called;
- new release → `gh release create <tag> --repo darthjee/vault --title <tag> --generate-notes --latest --verify-tag`,
  then `gh release upload <tag> ... --clobber` with the five assets;
- existing release (`view` succeeds) → no `create`, `upload --clobber` still runs;
- `GH_TOKEN` equals `GITHUB_TOKEN` inside the stub;
- `SHA256SUMS` has four lines, with bare file names, and verifies with `sha256sum -c`;
- `create` failure → non-zero exit, no upload.

Extend `scripts/test.sh` so `test/scripts/` runs on `BATS_IMAGE` only (not bash 3.2: CI runs these
scripts on the ubuntu machine executor). Add it to the `suites_in` list and the header comment.
`make lint` already covers `test/`.

## Files to Change
- `test/scripts/github_release.bats` — new suite.
- `test/scripts/helpers/gh` (or similar) — stub `gh`.
- `scripts/test.sh` — run `test/scripts/` on `BATS_IMAGE`.
