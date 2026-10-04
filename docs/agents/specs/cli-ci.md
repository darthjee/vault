# CLI Spec: CI

Part of the CLI spec for epic #20. Index: [cli-overview.md](cli-overview.md). Implemented in #22
(PR checks), #27 (`test-cli-e2e`) and #28 (`github-release`). Owner: `automation`.

CircleCI YAML only sets up executors, contexts and filters and calls make targets; logic lives
in `scripts/*.sh` (CI-only wrappers in `scripts/ci/`).

## PR pipeline

The `build-and-test` job (machine executor, real Docker) runs, in order:

| Step | Added by | Notes |
|------|----------|-------|
| `make lint` | existing (extended by #22) | Covers the CLI paths. |
| `make test` | existing (extended by #22) | bats on `BATS_IMAGE` and on the bash 3.2 image. |
| `make bundle-cli` | #22 | Checks that the bundle builds. |
| `make test-image` | existing | Builds the image (with the bundle) and runs the smoke test. |
| `make test-cli-e2e` | #27 | Runs **after** `make test-image`, on the same machine executor. |

- No new PR job and no new context: PR jobs never receive credentials.
- Sysbox is not available in CI. Runtime detection is unit-tested with the stub `docker`; only
  `--privileged` runs for real.

## Release pipeline

Release jobs run only on `X.Y.Z` tags (`branches: ignore: /.*/`).

```
check-version-tag ─┐
                   ├─> build-and-release ─┬─> update-description
build-and-test ────┘                      └─> github-release   (new)
```

| Job | Context | Make target | Notes |
|-----|---------|-------------|-------|
| `check-version-tag` | — | `check-version-tag TAG=$CIRCLE_TAG` | Also checks both `VAULT_VERSION` lines. |
| `build-and-test` | — | as in the PR pipeline | Unchanged name. |
| `build-and-release` | `docker-hub` | `ci-release-setup`, `release TAG=$CIRCLE_TAG` | Unchanged name; `release` bundles the CLI first. |
| `update-description` | `docker-hub` | `update-description` | Unchanged. |
| `github-release` | `github` | `github-release TAG=$CIRCLE_TAG` | New; requires `build-and-release`. |

### `github-release`

- Runs `make github-release TAG=$CIRCLE_TAG`; the logic is in `scripts/github_release.sh`.
- Creates the GitHub release for the tag, with generated release notes, and uploads the
  [released assets](#released-assets). It builds the bundle itself.
- **Credentials:** env var `GITHUB_TOKEN`, from the new restricted CircleCI context `github`,
  attached **only** to this job.
- **Release mode:** published (not a draft), marked Latest (`--latest`), with generated notes
  (`--generate-notes`), title = tag, on the existing tag. Repository `darthjee/vault`
  (overridable with `GITHUB_REPOSITORY`, for tests).
- **Executor and tooling:** CircleCI machine executor (`ubuntu-2404:current`), using the `gh` CLI
  shipped on the image (no pinned image). `GITHUB_TOKEN` is exported to `gh` as `GH_TOKEN`; a
  missing token fails with exit 1 and a clear message.
- **Failure:** a failing `github-release` never unpublishes or rolls back the Docker image.
- **Re-run (open point 9, settled by #28):** if `gh release view <tag>` succeeds, creation is
  skipped (title and notes untouched) and every asset is re-uploaded with
  `gh release upload --clobber`.

### Released assets

| Asset | Source |
|-------|--------|
| `vault` | `build/vault` |
| `install.sh` | `install.sh` (repo root) |
| `vault.bash` | `cli/completion/vault.bash` |
| `_vault` | `cli/completion/_vault` |
| `SHA256SUMS` | SHA-256 of the four files above, in `sha256sum` format, file names only. |

- Install URL: `https://github.com/darthjee/vault/releases/latest/download/install.sh`.
- The README (#29) shows a download-and-verify alternative to `curl | bash`.

## Manual prerequisite

Before the first tagged release that includes `github-release`: create the CircleCI context
`github` holding a `GITHUB_TOKEN` allowed to create releases on `darthjee/vault`. #28 documents
it in its PR. #28 pushes no tag.
