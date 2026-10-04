# Write operations.md
Create `docs/guides/vault/operations.md`: running a Vault stack day to day.

- Header: one-line purpose + link to `../vault.md`.
- Persistence and the data volume: `-v vault-data:/var/lib/docker`; what is lost without it
  (pulled images, inner named volumes such as database data); link to `concepts.md` for the model.
  The CLI names it `vault-<name>-data` and `vault down` never removes it (link to `cli.md`).
- Shutdown: SIGTERM / SIGINT → `docker compose down` → stop `dockerd`; Docker's default 10s grace
  period may be too short; `docker stop -t 60 <container>`, `docker run --stop-timeout 60`; CLI
  default stop timeout `60`.
- Logs: `docker logs [-f] <container>`, `vault logs -f`.
- Compose commands against a running stack: `docker exec <container> docker compose ps` (workdir
  `/vault`), `vault compose ps`.
- Service failures: the container exits only when compose exits; `restart:` policies handle
  individual crashes; fail fast with `COMPOSE_UP_ARGS="--abort-on-container-exit"`.
- Never share one `/var/lib/docker` volume between two running containers (not detected; both
  daemons corrupt each other's state).

## Files to Change
- `docs/guides/vault/operations.md` — new page.
