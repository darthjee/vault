# Automation Plan: Docker image smoke test (make test-image)

Main plan: [plan.md](plan.md)

## Shared contracts

- Rely on `dev` providing `test/fixture/docker-compose.yml` (one `nginx:<x.y>-alpine` service publishing `80:80`, `GET /` → 200, no `images/` folder).
- Produce `scripts/test_image.sh` reading `IMAGE` and `SMOKE_TIMEOUT` from the environment.
- Produce `test-image: build-image` in the `Makefile`, plus `SMOKE_TIMEOUT ?= 120` (exported).

## Implementation Steps

### Step 1 — Add `scripts/test_image.sh`

Follow the style of `scripts/lint.sh` / `scripts/test.sh`: `#!/usr/bin/env bash`, usage header comment, `set -euo pipefail`, `cd` to the repo root, small focused functions (public before `_private`).

1. Validate inputs: `IMAGE` non-empty; `SMOKE_TIMEOUT` positive integer (default `120` when unset). Fail fast with a clear message otherwise.
2. Use a unique container name, e.g. `vault-smoke-$$`.
3. Install an `EXIT` trap that runs cleanup: `docker rm -fv "$name" >/dev/null 2>&1 || true`. `-v` removes the anonymous `/var/lib/docker` volume. Vault creates no outer networks (default bridge), so nothing else to remove; keep cleanup idempotent.
4. Add a `fail <check>` helper that prints `test-image: FAILED: <check>`, dumps `docker logs "$name"` (best-effort), and exits 1.
5. Start: `docker run -d --privileged --name "$name" -v "$PWD/test/fixture:/vault:ro" -p 127.0.0.1::80 "$IMAGE"`.
6. Read the host port: `docker port "$name" 80/tcp` → take the port from the first `127.0.0.1:<port>` line.
7. Wait for HTTP: every 2s until `SMOKE_TIMEOUT` elapses, `curl -fsS -o /dev/null "http://127.0.0.1:$port/"`. Also bail out early with `fail` if the container is no longer running (`docker inspect -f '{{.State.Running}}'`). Timeout → `fail "port 80 did not answer within ${SMOKE_TIMEOUT}s"`.
8. Assert no TCP listener on 2375: `docker exec "$name" netstat -ltn`; fail if any line matches `:2375[[:space:]]`. Fail too if the `netstat` call itself fails (so the check can't pass silently).
9. Stop: `docker stop -t 30 "$name"`; then `docker inspect -f '{{.State.ExitCode}}' "$name"` must be `0`, otherwise `fail` naming the actual code.
10. Print `test-image: OK` and exit 0 (the trap still removes the container).

### Step 2 — Wire `make test-image`

In `Makefile`: add `SMOKE_TIMEOUT ?= 120` next to the other variables, add it (and `IMAGE`) to the `export` line, and replace the stub with:

```make
test-image: build-image
	scripts/test_image.sh
```

Make the script executable (`chmod +x`, committed with the mode bit like the other scripts).

## Files to Change

- `scripts/test_image.sh` — new: the smoke-test logic.
- `Makefile` — `SMOKE_TIMEOUT` variable, export `IMAGE`/`SMOKE_TIMEOUT`, real `test-image` recipe depending on `build-image`.

## CI Checks

- `scripts/`, `Makefile`: `make lint`.
- Whole feature: `make test-image` on a host that allows `--privileged` (Docker Desktop is fine).

## Notes

- If the exit code after `docker stop` isn't 0, don't loosen the assertion: it means the SIGTERM path (#6: `compose down` then collecting compose's exit code) doesn't yield 0 when `compose up` is stopped. Report it to `dev`/architect with the observed code and logs.
- `docker port` may also print an IPv6 line; filter on `127.0.0.1`.
- The inner dockerd pulls `nginx` on every run, so the run needs network access; `SMOKE_TIMEOUT` covers dockerd startup plus the pull.
- `.circleci/` doesn't exist yet; CI wiring is #8.
