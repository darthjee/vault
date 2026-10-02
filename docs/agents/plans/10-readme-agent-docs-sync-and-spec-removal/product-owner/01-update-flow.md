# Update flow.md

Rewrite `docs/agents/flow.md` so it describes the entrypoint as built (`source/bin/entrypoint.sh`, `source/lib/*.sh`). Sources: `docs/agents/specs/docker-image/image.md` → Dockerd startup, Entrypoint flow, Exit codes and messages, Edge cases 1–8.

- **Overview steps:**
  1. Pre-checks: `VAULT_DOCKERD_TIMEOUT` must be a positive integer. A tmpfs mount probe checks for privileges (needs `CAP_SYS_ADMIN`, granted by both `--privileged` and Sysbox).
  2. Start dockerd in the background with an explicit `--host=unix:///var/run/docker.sock`. The base `dockerd-entrypoint.sh` would otherwise add an unauthenticated `tcp://0.0.0.0:2375` listener when `DOCKER_TLS_CERTDIR=""`.
  3. Wait (unchanged).
  4. Preload (unchanged; failing load names the file, stops dockerd, exits 1).
  5. Run compose in the background and `wait` on it, so traps fire immediately.
  6a. Compose exits on its own → stop dockerd only, **no `compose down`**.
  6b. SIGTERM / SIGINT → `compose down`, then stop dockerd.
  7. Exit with compose's exit code.
- Note that the signal trap is installed before step 1.
- **New `## Exit codes and messages` section:** the table from the spec (compose exit, privilege probe, invalid timeout, dockerd timeout, tarball load failure, signal before compose = `128 + signal`, `compose down` failure = warning, compose's code kept). Remove the issue-number references (#5, #6, #7).
- **New `## Edge cases` section:** a short list covering no compose file (compose's own error and exit code), a second signal during shutdown (ignored), and the two documentation-only cases: shutdown longer than `docker stop`'s 10s → `docker stop -t` / `--stop-timeout`; never share one `/var/lib/docker` volume between two running containers.
- Keep `## Service failures` and `## State across restarts`.
- Change the overview sentence so it covers both `--privileged` and `--runtime=sysbox-runc`.

## Files to Change
- `docs/agents/flow.md` — rewritten flow, new exit codes and edge cases sections.
