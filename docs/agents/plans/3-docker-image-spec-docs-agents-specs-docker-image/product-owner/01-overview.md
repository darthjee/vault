# Write overview.md
Create `docs/agents/specs/docker-image/overview.md`, the entry point of the spec. It contains:
- **Purpose and lifecycle:** a temporary spec for epic #2. It overrides `AGENTS.md` and `docs/agents/*` where they conflict. A sub-issue PR that deviates from it updates it in the same PR. #10 deletes it.
- **Scope:** what the spec decides (contracts, open points, entrypoint behaviour) vs. what it leaves to each sub-issue (function names and signatures, test case lists, exact YAML and Makefile recipes, README prose).
- **Shared contracts:**
  - Makefile targets: `build-image`, `lint`, `test`, `test-image`, `release TAG=x` (fails fast without `TAG`), `update-description`. Variables: `SHELLCHECK_IMAGE`, `BATS_IMAGE`, `DOCKER_VERSION`.
  - Image paths: `/usr/local/lib/vault/`, `/usr/local/bin/vault-entrypoint`, `/vault`, `/vault/images`.
  - Env vars: `COMPOSE_UP_ARGS`, and `VAULT_DOCKERD_TIMEOUT` (default 30). Compose's own variables are referenced in `architecture.md`.
  - Credentials: `DOCKER_HUB_USERNAME` / `DOCKER_HUB_PASSWORD` in a restricted CircleCI context.
  - Version rule: the tag must equal `VERSION` and the README `**Current Version:**` line. The initial version is `0.1.0`.
- **Sub-issue map:** a table linking #4–#10 to the spec files and sections each one implements.
- **Conflicts with the existing docs:** credentials context, explicit unix `--host`, no `down` when compose exits on its own, the new Makefile variables and `DOCKER_VERSION` build arg, and `scripts/ci/`.
- **Alternatives considered:** a single file, editing the existing docs directly, or keeping the spec in issue bodies only, each with the reason it was rejected.
- **Future work:** vulnerability scanning, Sysbox in CI, Renovate/Dependabot for the pins.

## Files to Change
- `docs/agents/specs/docker-image/overview.md` — new.
