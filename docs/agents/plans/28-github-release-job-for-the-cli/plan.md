# Plan: GitHub release job for the CLI

Issue: [28-github-release-job-for-the-cli.md](../../issues/28-github-release-job-for-the-cli.md)

## Overview
Add `scripts/github_release.sh` and `make github-release TAG=X.Y.Z`. Together they build the CLI
bundle, compute `SHA256SUMS`, and use the `gh` CLI to create (or reuse) a published GitHub release
marked Latest, with generated notes. They then upload the five released assets with `--clobber`.
A new tag-only CircleCI job, `github-release`, runs it after `build-and-release`, using the new
restricted `github` context. The specs record the settled choices (tooling, re-run behaviour).

## Agents involved

- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

- **Make target:** `make github-release TAG=X.Y.Z` → `scripts/github_release.sh X.Y.Z`. Missing `TAG`
  fails before any build work (reuse `require-tag`).
- **Credentials:** env var `GITHUB_TOKEN` (exported to `gh` as `GH_TOKEN`), from CircleCI context
  `github`, attached only to the `github-release` job. Missing token → exit 1 with a clear message.
- **Repository:** `darthjee/vault` (overridable with `GITHUB_REPOSITORY`, for tests).
- **Tooling:** `gh` as shipped on the CircleCI `ubuntu-2404:current` machine image; no pinned image.
- **Release:** published (not a draft), `--latest`, `--generate-notes`, title = tag, on the existing tag.
- **Re-run (open point 9, settled):** if `gh release view <tag>` succeeds, skip creation (notes
  untouched) and re-upload every asset with `gh release upload --clobber`.
- **Assets (upload names):** `vault` (from `build/vault`), `install.sh`, `vault.bash`, `_vault`,
  `SHA256SUMS` (`sha256sum` output of the four, file names only, in that order).
- **CI graph:** `build-and-release` → `github-release` (in parallel with `update-description`),
  with the same `X.Y.Z` tag filters.
- **Tests:** new `test/scripts/` bats suite with a stub `gh`, run on `BATS_IMAGE` only.
