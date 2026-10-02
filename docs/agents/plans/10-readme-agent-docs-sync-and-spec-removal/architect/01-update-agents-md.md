# Update AGENTS.md

Bring `AGENTS.md` in line with the implementation.

- **Runtime flow:** add step 0 (pre-checks: timeout validation + privilege probe). Step 1 starts dockerd with an explicit unix `--host`, with no TCP listener. Split step 5: compose exits on its own → stop dockerd only; SIGTERM / SIGINT → `compose down`, then stop dockerd.
- **Conventions:** `COMPOSE_UP_ARGS` is whitespace split with no quoting support; `VAULT_DOCKERD_TIMEOUT` must be a positive integer.
- **Release:** credentials live in the restricted CircleCI context `docker-hub`, used only by the release jobs (not project env vars). `build-and-release` runs `make ci-release-setup` before `make release`. Full target list and Makefile variables as in the shared contracts.
- **Future work:** add vulnerability scanning of the published image, Sysbox in CI, and Renovate / Dependabot for the pinned images, next to the existing CLI item.
- **Documentation table:** remove the `Docker image spec` row and the "During epic #2 … overrides" sentence.
- **Issues section:** naming convention `docs/agents/issues/<issue_id>-<slug>.md`, example `docs/agents/issues/10-readme-agent-docs-sync-and-spec-removal.md`. The Plans section shows `<issue_id>-<slug>/plan.md` to match the tooling (`docs/agents/plans/10-readme-agent-docs-sync-and-spec-removal/`).

## Files to Change
- `AGENTS.md` — flow, conventions, release, future work, documentation table, naming conventions.
