# Update the docs
Document the new script and target, and fix the wrong claim that `gh` comes from the machine image.

- `AGENTS.md`, "Release (CircleCI)":
  - `github-release` bullet: it now runs `make ci-github-release-setup` (installs `gh` from GitHub's apt repo, `scripts/ci/install_gh.sh`) then `make github-release TAG=$CIRCLE_TAG`; replace "using the `gh` CLI from the machine image" accordingly.
  - CI-only wrappers sentence: add installing `gh` to the list.
  - Makefile targets list: add `ci-github-release-setup` (CI-only) next to `ci-release-setup`.
- `docs/agents/folder-structure.md`:
  - `scripts/ci/` list: add `install_gh.sh` — installs the GitHub CLI from cli.github.com (apt) for the `github-release` job.
  - Makefile table: add a `ci-github-release-setup` row — "CI-only: installs the GitHub CLI (`scripts/ci/install_gh.sh`)."
- `.claude/agents/automation.md`: add `ci-github-release-setup` to the Makefile targets it lists, if it lists the CI-only ones.

## Files to Change
- `AGENTS.md` — release section, CI wrappers and Makefile targets.
- `docs/agents/folder-structure.md` — `scripts/ci/` list and Makefile table.
- `.claude/agents/automation.md` — targets list (if applicable).
