# Dev Plan: Docker image smoke test (make test-image)

Main plan: [plan.md](plan.md)

## Shared contracts

- Produce `test/fixture/docker-compose.yml` with exactly one service using `nginx:1.29-alpine` (pinned by tag) and `ports: ["80:80"]`; `GET /` must return HTTP 200.
- No `test/fixture/images/` folder: the smoke test relies on preload being skipped (edge case 4).
- `automation`'s `scripts/test_image.sh` mounts `test/fixture` read-only at `/vault`; don't put anything there that needs to be writable.

## Implementation Steps

### Step 1 — Add the smoke-test compose fixture

Create `test/fixture/docker-compose.yml` with a single service (e.g. `web`), `image: nginx:1.29-alpine`, `ports: ["80:80"]`. Keep it minimal: no build, no volumes, no healthcheck, no `version:` key (obsolete in compose v2 and prints a warning). Confirm the tag exists on Docker Hub; if `1.29-alpine` is unavailable, use the current stable `nginx:<x.y>-alpine` tag and tell `automation` (the tag isn't referenced by the script, only by the fixture).

## Files to Change

- `test/fixture/docker-compose.yml` — new: the one-service fixture.

## CI Checks

- `test/`: `make lint`, `make test`, `make test-image` (run after `automation`'s work lands; needs a host that allows `--privileged`).

## Notes

- `make lint` only picks up `*.sh` / `*.bats`, so the YAML file is not linted.
