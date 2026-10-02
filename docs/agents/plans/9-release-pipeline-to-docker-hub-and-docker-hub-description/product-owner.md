# Product Owner Plan: Release pipeline to Docker Hub and Docker Hub description

Main plan: [plan.md](plan.md)

## Shared contracts

- The CircleCI context is named `docker-hub`.
- `docker_hub.sh` is fetched from `darthjee/docker` at commit `91b11fb949bb0f71670e390fdc97df831c46af70`, path `scripts/0.9.0/home/sbin/docker_hub.sh`, and verified by its sha256.
- `ci-release-setup` is a new CI-only make target.

## Implementation Steps

### Step 1 — Record the release decisions in the CI spec
In `docs/agents/specs/docker-image/ci.md`:

- **Credentials:** set the context name to `docker-hub` in the table.
- **Docker Hub description:** note that `docker_hub.sh` lives in the `darthjee/docker` repo, not `darthjee/scripts`, and is fetched at a pinned commit and checked by sha256 in `scripts/ci/update_description.sh`.
- **Manual prerequisites:** name the context `docker-hub`.

Add the `ci-release-setup` row to the Makefile table in `docs/agents/specs/docker-image/tooling.md`, and remove the stub sentence's mention of #9.

## Files to Change
- `docs/agents/specs/docker-image/ci.md` — context name, `docker_hub.sh` source and pinning.
- `docs/agents/specs/docker-image/tooling.md` — the `ci-release-setup` target, and the stub note.

## Notes
- `AGENTS.md` still says "CircleCI project env vars". It is a root-level file outside this agent's scope. The README/agent-docs sync in #10 covers it.
