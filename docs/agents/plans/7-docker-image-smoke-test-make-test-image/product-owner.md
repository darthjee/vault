# Product Owner Plan: Docker image smoke test (make test-image)

Main plan: [plan.md](plan.md)

## Shared contracts

- `automation` adds the Make variable `SMOKE_TIMEOUT ?= 120` (seconds to wait for the published port) and makes `test-image` depend on `build-image`.
- The fixture lives in `test/fixture/docker-compose.yml` (`nginx:<x.y>-alpine`, `80:80`).

## Implementation Steps

### Step 1 — Update the docker-image spec

In `docs/agents/specs/docker-image/tooling.md`:

- **Makefile variables table:** add `SMOKE_TIMEOUT` | `?= 120`; seconds `test-image` waits for the published port.
- **Makefile targets table:** `test-image` row: note it depends on `build-image`.
- **Smoke test section:** record the decisions: fixture `test/fixture/docker-compose.yml` with pinned `nginx:<x.y>-alpine`; logic in `scripts/test_image.sh`; random host port on `127.0.0.1` read with `docker port`; curl polled every 2s up to `SMOKE_TIMEOUT`; 2375 check via `docker exec … netstat -ltn`; `docker stop -t 30` then exit code 0 via `docker inspect`; cleanup `docker rm -fv` in an `EXIT` trap; on failure, print the failed check and the container logs.
- **Stubs paragraph:** `test-image` is no longer a stub (implemented in #7).

## Files to Change

- `docs/agents/specs/docker-image/tooling.md` — the updates above.

## Notes

- If `dev` ends up using a different nginx tag, use the final one.
