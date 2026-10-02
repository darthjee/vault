# Issue: README, agent docs sync and spec removal

## Description
Part of epic #2, and its last step. Write the user-facing `README.md`, bring `AGENTS.md` and the agent docs in line with what was built in #4–#9, fold the still-relevant content of the temporary spec (`docs/agents/specs/docker-image/`) into the permanent docs, then delete the spec and every reference to it.

## Problem
- `README.md` contains only the title and the `**Current Version:**` line. `DOCKERHUB_DESCRIPTION.md` already links to `README.md#security`, which does not exist yet.
- The permanent docs still describe the pre-spec design and use "planned" wording, while the spec overrides them. Known drift between the docs and the implementation:
  - **Entrypoint flow:** no pre-check step (timeout validation + tmpfs privilege probe, `source/lib/preflight.sh`); no mention that dockerd is started with an explicit unix `--host`; `docker compose down` is described as always run, but it only runs on SIGTERM / SIGINT. When compose exits on its own, only dockerd is stopped. Signal edge cases (signal before compose starts → `128 + signal`; second signal ignored) are not documented.
  - **Library list:** `architecture.md` and `folder-structure.md` omit `preflight.sh`.
  - **Release credentials:** `AGENTS.md` says CircleCI project env vars; CI actually uses the restricted `docker-hub` context.
  - **Makefile:** the docs list only six targets; the real Makefile also has `bump-version`, `check-version-tag` and `ci-release-setup`, plus the `SHELLCHECK_IMAGE`, `BATS_IMAGE`, `IMAGE` and `DOCKER_VERSION` variables.
  - **`scripts/`:** the docs list only `bump_version.sh`, `check_tag_version.sh` and `ci/*`. The real folder also has `lint.sh`, `test.sh`, `test_image.sh` and `release.sh`, and the docs give no rule for what goes in `scripts/ci/`.
  - **Future work:** the spec records vulnerability scanning, Sysbox in CI and Renovate/Dependabot; `AGENTS.md` only lists the CLI.
- `AGENTS.md` still has the `specs/` row and the "During epic #2 … overrides" note.
- The issue file naming convention is documented as `<issue_id>_<issue_name>.md` (`AGENTS.md`, `.claude/agents/product-owner.md`), but the tooling writes `<issue_id>-<slug>.md` (e.g. `10-readme-agent-docs-sync-and-spec-removal.md`).

## Expected Behavior
- **`README.md`** (keeping the `**Current Version:**` line used by `check-version-tag` / `bump_version.sh`):
  - what Vault is (with the host → container → services diagram);
  - usage: `docker run --runtime=sysbox-runc` (recommended) or `--privileged` (fallback); mounting or `COPY`ing the compose project into `/vault`; argument passthrough to `docker compose`; ports (`-p` + inner `ports:`, `EXPOSE 80` convention); the `/var/lib/docker` named volume; offline preload with `/vault/images/*.tar`;
  - environment variables: `COMPOSE_FILE`, `COMPOSE_PROJECT_NAME`, `COMPOSE_UP_ARGS` (whitespace split, **no quoting support**), `VAULT_DOCKERD_TIMEOUT` (positive integer, default 30);
  - behaviour notes: exit code = compose exit code; service failures and `--abort-on-container-exit`; bind mounts refer to the outer container filesystem; shutdown takes longer than `docker stop`'s 10s → use `docker stop -t` / `--stop-timeout` (spec edge case 9); never share one `/var/lib/docker` volume between two running containers, which is not detected (spec edge case 10);
  - supported / unsupported runtimes (from spec → Runtime privileges): rootless, `--cap-add` and mounting the host `docker.sock` are unsupported; not usable on most managed platforms (ECS Fargate, Cloud Run, Kubernetes without privileged pods);
  - a required **`## Security`** section (the anchor `#security` is linked from `DOCKERHUB_DESCRIPTION.md`): risks of `--privileged` (host escape, device access, no seccomp/AppArmor), root inside the container, why Sysbox is safer, never exposing the inner Docker socket over TCP;
  - development: the Makefile targets (`build-image`, `lint`, `test`, `test-image`).
- **`AGENTS.md`** and **`docs/agents/{folder-structure,architecture,flow}.md`** describe the image as built (all the drift listed above fixed), with no "planned" wording.
- The issue file naming convention is documented as `<issue_id>-<slug>.md` everywhere it appears.
- **Spec removal:** `docs/agents/specs/` is deleted; no reference to it remains (including the table row and the override note in `AGENTS.md`).

## Solution
1. Fold the spec into the permanent docs:
   - entrypoint flow, exit codes, edge cases → `flow.md`;
   - libraries, image paths, configuration, runtime privileges, security decisions → `architecture.md`;
   - Makefile targets / variables, `scripts/` (and the `scripts/ci/` rule) → `folder-structure.md` and `AGENTS.md`;
   - credentials (restricted `docker-hub` context), CI and release → `AGENTS.md`;
   - spec future work → `AGENTS.md` → Future work.
   - Not carried over: the spec's sub-issue map, conflicts table and alternatives (they only applied while the epic was in progress).
2. Write `README.md`.
3. Fix the issue file naming convention in `AGENTS.md` and `.claude/agents/product-owner.md`.
4. Delete `docs/agents/specs/` and grep the repo (outside `.claude/state/`) for `specs/` to confirm no reference remains.

### Ownership
- `docs/agents/*.md`: `product-owner`.
- `README.md`, `AGENTS.md` and `.claude/agents/product-owner.md`: `architect`, because the `product-owner` agent may not edit root-level files or `.claude/`.

### Out of scope
- Code, Makefile, CI or `DOCKERHUB_DESCRIPTION.md` changes.

## Depends on
All other sub-issues of #2 (#3–#9, all closed).

## Done when
- No reference to `docs/agents/specs/` remains.
- The docs describe the image as built.
- `README.md` has the sections above, including `## Security` and a short Development section, and keeps the `**Current Version:**` line.
- The issue file naming convention reads `<issue_id>-<slug>.md`.
