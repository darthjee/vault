# Automation Plan: GitHub release job for the CLI

Main plan: [plan.md](plan.md)

## Shared contracts

- Implements `scripts/github_release.sh X.Y.Z` and `make github-release TAG=X.Y.Z` (fails fast
  without `TAG`, through the existing `require-tag` prerequisite).
- Reads `GITHUB_TOKEN` (required) and passes it to `gh` as `GH_TOKEN`. Repository is `darthjee/vault`,
  overridable with `GITHUB_REPOSITORY`.
- Release: published, `--latest`, `--generate-notes`, `--title <tag>`, `--verify-tag`. If it already
  exists, skip creation and only re-upload the assets with `--clobber`.
- Assets: `vault`, `install.sh`, `vault.bash`, `_vault`, `SHA256SUMS` (in `sha256sum` format, file names only).
- CI job `github-release`, context `github`, requires `build-and-release`, `X.Y.Z` tag filters only.

## Steps

- [01 — Add scripts/github_release.sh](automation/01-github-release-script.md)
- [02 — Add the make target and CircleCI job](automation/02-make-target-and-ci-job.md)
- [03 — Cover the script with bats](automation/03-bats-coverage.md)

## CI Checks
- `scripts/`, `test/scripts/`: `make lint` (CI job: `build-and-test`)
- `test/scripts/`: `make test` (CI job: `build-and-test`)
- `.circleci/config.yml`: `circleci config validate` (if the CLI is installed)

## Notes
- No tag is pushed. The PR description must document the **manual prerequisite**: create the CircleCI
  context `github` holding a `GITHUB_TOKEN` (fine-grained PAT with `Contents: read and write` on
  `darthjee/vault`). Restrict it so it's only used by the `github-release` job.
- A failing `github-release` never rolls back the Docker image; the job can be re-run safely
  because of the `--clobber` re-upload.
- `test/scripts/` is a new folder. Extend `.claude/agents/automation.md`'s scope to list it. That is a
  `.claude/` change, so it's done by the architect when reviewing, not by `automation`.
