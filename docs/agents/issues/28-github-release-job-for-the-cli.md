# Issue: GitHub release job for the CLI

## Description
Part of epic #20 (Vault CLI). Depends on the install-path sub-issue (#26). Agent: `automation`.
Follow `docs/agents/specs/*.md`, mainly [cli-ci.md](../specs/cli-ci.md).

## Problem
The `curl | bash` install URL
(`https://github.com/darthjee/vault/releases/latest/download/install.sh`) and the standalone CLI
download both need GitHub releases with assets. The README already points users at the
release's `SHA256SUMS` to check the download. Today, CI only publishes to Docker Hub, so all of
these links are broken.

## Expected Behavior
- `scripts/github_release.sh` and `make github-release TAG=X.Y.Z` (fails fast without `TAG`, before any build work):
  - builds the CLI bundle (`build/vault`) itself;
  - uses the `gh` CLI (as shipped on the CircleCI ubuntu machine image), authenticated through `GITHUB_TOKEN`;
  - creates the GitHub release for the tag as a published release marked **Latest**, with generated release notes;
  - uploads the released assets: `vault` (`build/vault`), `install.sh`, `vault.bash`, `_vault`
    and `SHA256SUMS` (SHA-256 of the four files, `sha256sum` format, file names only).
- **Re-run (settles open point 9):** if the release for the tag already exists, keep it (notes untouched)
  and re-upload all assets, replacing the existing ones (`--clobber`).
- A new CircleCI job, `github-release`:
  - runs only on `X.Y.Z` tags, after `build-and-release` (in parallel with `update-description`);
  - uses `GITHUB_TOKEN` from a new restricted CircleCI context, `github`, attached only to this job;
  - the CircleCI YAML only calls the make target.
- A failing `github-release` never unpublishes or rolls back the Docker image; the job can be re-run.
- **Manual prerequisite** (documented in the PR): create the `github` CircleCI context with a
  token allowed to create releases on `darthjee/vault`.
- `docs/agents/specs/cli-ci.md` (executor/tooling) and open point 9 in `cli-overview.md` are updated as settled.
- No tag is pushed in this sub-issue.
- `make lint` passes, and the script is covered where practical (bats with a stub `gh`, no real GitHub calls).
