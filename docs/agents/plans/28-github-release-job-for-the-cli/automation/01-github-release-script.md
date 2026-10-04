# Add scripts/github_release.sh

Create `scripts/github_release.sh`, following the style of `scripts/release.sh` (usage header comment,
`set -euo pipefail`, `ROOT` resolution and `cd "$ROOT"`, `fail()` helper prefixed `github-release:`).

Behaviour, in order:

1. `tag="${1:-}"`; empty → print `usage: $0 X.Y.Z` to stderr, exit 1.
2. `GITHUB_TOKEN` unset/empty → `github-release: GITHUB_TOKEN must be set`, exit 1. Export
   `GH_TOKEN="$GITHUB_TOKEN"`. `repo="${GITHUB_REPOSITORY:-darthjee/vault}"`.
3. `command -v gh` missing → `github-release: gh not found in PATH`, exit 1.
4. Run `scripts/bundle_cli.sh` (the script builds the bundle itself, so it works standalone).
5. Stage the assets in a fresh dir `build/github-release/` (wiped first): copy `build/vault`,
   `install.sh`, `cli/completion/vault.bash`, `cli/completion/_vault`. Fail if any source is missing.
   In that dir, run `sha256sum vault install.sh vault.bash _vault > SHA256SUMS` (file names only).
6. If `gh release view "$tag" --repo "$repo"` succeeds, print that the release exists and that the
   assets will be replaced. Otherwise run `gh release create "$tag" --repo "$repo" --title "$tag"
   --generate-notes --latest --verify-tag`.
7. `gh release upload "$tag" --repo "$repo" --clobber` with the five staged files.
8. Print `github-release: released <tag> to <repo>`.

`build/` is already git-ignored, so the staging dir needs no `.gitignore` change.

## Files to Change
- `scripts/github_release.sh` — new script (mode 0755).
