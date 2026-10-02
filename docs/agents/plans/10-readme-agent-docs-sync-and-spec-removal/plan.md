# Plan: README, agent docs sync and spec removal

Issue: [10-readme-agent-docs-sync-and-spec-removal.md](../../issues/10-readme-agent-docs-sync-and-spec-removal.md)

## Overview

Close epic #2 on the documentation side. `product-owner` updates `docs/agents/{flow,architecture,folder-structure}.md` so they describe the image as built, moving in the still-relevant content of `docs/agents/specs/docker-image/`. `architect` writes the user-facing `README.md`, updates `AGENTS.md`, fixes the issue file naming convention, and finally deletes the spec. No code, Makefile, CI or `DOCKERHUB_DESCRIPTION.md` changes.

## Agents involved

- [product-owner](product-owner.md): `docs/agents/*.md`
- [architect](architect.md): `README.md`, `AGENTS.md`, `.claude/agents/product-owner.md`, spec removal

## Shared contracts

- **Source of truth:** the implementation (`Dockerfile`, `source/`, `Makefile`, `scripts/`, `.circleci/config.yml`) wins over the spec wherever they disagree.
- **Ordering:** the spec folder `docs/agents/specs/` is deleted **last** (architect step 04), after both agents have taken what they need from it. Until then, neither agent links to it from new content.
- **Doc file names stay unchanged** (`flow.md`, `architecture.md`, `folder-structure.md`, `contributing.md`), so the `AGENTS.md` documentation table only loses its `specs/` row.
- **Section anchors other docs link to:**
  - `README.md` must have a `## Security` heading (`#security`, linked from `DOCKERHUB_DESCRIPTION.md` and from `architecture.md` → Runtime requirements).
  - `architecture.md` keeps `## Configuration` and `## Runtime requirements`.
- **Facts both agents must state the same way:**
  - Entrypoint flow: pre-checks (timeout validation + tmpfs privilege probe) → start dockerd with explicit `--host=unix:///var/run/docker.sock` (no TCP listener) → wait (`VAULT_DOCKERD_TIMEOUT`, positive integer, default 30) → preload `/vault/images/*.tar` → compose in the background, `wait`ed on → **compose exits on its own: stop dockerd only (no `compose down`)**; **SIGTERM / SIGINT: `compose down`, then stop dockerd** → exit with compose's exit code.
  - `COMPOSE_UP_ARGS`: whitespace split (`read -ra`), no quoting support.
  - Libraries: `preflight.sh`, `dockerd.sh`, `images.sh`, `compose.sh`, `signals.sh`.
  - Release credentials: `DOCKER_HUB_USERNAME` / `DOCKER_HUB_PASSWORD` in the restricted CircleCI context `docker-hub`, used only by the release jobs.
  - Makefile targets: `build-image`, `lint`, `test`, `test-image`, `bump-version VERSION=X.Y.Z`, `check-version-tag TAG=X.Y.Z`, `release TAG=x`, `update-description`, `ci-release-setup` (CI-only). Variables: `SHELLCHECK_IMAGE`, `BATS_IMAGE`, `IMAGE`, `DOCKER_VERSION`.
  - Issue file naming convention: `docs/agents/issues/<issue_id>-<slug>.md` (e.g. `10-readme-agent-docs-sync-and-spec-removal.md`).
