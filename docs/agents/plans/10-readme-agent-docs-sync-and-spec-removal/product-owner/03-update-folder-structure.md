# Update folder-structure.md

Make `docs/agents/folder-structure.md` describe the repo as it exists.

- Remove the "planned layout" note at the top.
- **`scripts/` row:** list the real scripts (`bump_version.sh`, `check_tag_version.sh`, `lint.sh`, `test.sh`, `test_image.sh`, `release.sh`, `ci/`). Add a `## scripts/` subsection with the rules from spec `tooling.md` → Scripts vs Makefile: make is the only entry point; multi-line recipes move to `scripts/*.sh`; CI-only steps (`docker login`, buildx/QEMU setup, fetching `docker_hub.sh`) live in `scripts/ci/` (`docker_login.sh`, `setup_buildx.sh`, `update_description.sh`); everything is shellchecked.
- **`Makefile` row:** all targets per [plan.md → Shared contracts](../plan.md#shared-contracts), plus a short variables table (`SHELLCHECK_IMAGE`, `BATS_IMAGE`, `IMAGE ?= darthjee/vault:dev`, `DOCKER_VERSION`).
- **`source/lib/` row:** add `preflight.sh`.
- **`test/` row:** `lib/*.bats` (unit tests) and `fixture/docker-compose.yml` (smoke-test stack).
- **`docs/agents/` row:** issues and plans, with no mention of specs.

## Files to Change
- `docs/agents/folder-structure.md` — remove the "planned" wording; describe the real scripts, Makefile and test layout.
