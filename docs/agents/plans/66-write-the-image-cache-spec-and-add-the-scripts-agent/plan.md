# Plan: Write the image-cache spec and add the scripts agent

Issue: [66-write-the-image-cache-spec-and-add-the-scripts-agent.md](../../issues/66-write-the-image-cache-spec-and-add-the-scripts-agent.md)

## Overview

Documentation-only change for epic #65. `product-owner` writes the five `docs/agents/specs/image-cache-*.md` files, registers the spec in `docs/agents/specs.md` and updates the ownership rows of `docs/agents/folder-structure.md`. `architect` adds `.claude/agents/scripts.md` and moves ownership of top-level `scripts/*.sh` and `test/scripts/` from `automation` to `scripts` in every agent file and in `AGENTS.md`. No script, `Dockerfile`, Makefile or CI behaviour changes.

## Agents involved

- [product-owner](product-owner.md)
- [architect](architect.md)

## Shared contracts

**Scripts agent** (written into `image-cache-agents.md` by `product-owner`, implemented in `.claude/` / `AGENTS.md` by `architect` — both must state exactly this):

- Name: `scripts`. Tools: `Read, Edit, Write, Bash`.
- Description: `Vault scripts specialist. Use for any task involving the repo shell scripts under scripts/*.sh (build, test, release, version and link-check scripts) or their bats tests under test/scripts/.`
- Owns: every top-level `scripts/*.sh` (`bump_version.sh`, `bundle_cli.sh`, `check_guides_links.sh`, `check_tag_version.sh`, `github_release.sh`, `lint.sh`, `release.sh`, `test.sh`, `test_cli_e2e.sh`, `test_image.sh`) and `test/scripts/`.
- Rule: **the path decides the owner**, no exceptions. For coupled scripts the domain agent states what is needed and reports it; `scripts` implements it:
  - `test_image.sh` → domain `dev`; `test_cli_e2e.sh`, `bundle_cli.sh` → domain `cli`;
  - `release.sh` → `automation` owns the release design (platforms, tags, cache and reproducibility flags as fixed by the spec); `scripts` owns the file.
- `automation` keeps: `.circleci/`, `Makefile`, `scripts/ci/*`, `VERSION`, `DOCKERHUB_DESCRIPTION.md`, `test/bash32/`, `build/`, and the release / buildx design.
- Agent-table scope string (`AGENTS.md`, `architect.md`):
  - `scripts` → `scripts/*.sh` (not `scripts/ci/`), `test/scripts/` — repo shell scripts and their bats tests
  - `automation` → `.circleci/`, `Makefile`, `scripts/ci/`, `VERSION`, `DOCKERHUB_DESCRIPTION.md`, `test/bash32/`, `build/` — CI, build, release design and publishing

**Spec contracts** (the overview fixes them; `architect` only relies on the agent part):

- Spec prefix `image-cache-`; *Active specs* row: `image-cache-` | #65 | #71.
- Cache tag `darthjee/vault:buildcache`; `build-and-test` imports anonymously, `build-and-release` imports and exports (`mode=max`); PR builds never write.
- `SOURCE_DATE_EPOCH` = `git log -1 --format=%ct`.
- Sequencing: #66 → #68 → #69 → #70 → #71.

## CI Checks

- whole repo: `make lint`, `make test` (CI job: `build-and-test`)
- spec cross-links (manual, not in CI): `scripts/check_guides_links.sh docs/agents/specs`
