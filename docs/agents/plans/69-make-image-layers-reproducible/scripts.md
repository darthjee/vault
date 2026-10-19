# Scripts Plan: Make image layers reproducible

Main plan: [plan.md](plan.md)

## Shared contracts

- `scripts/release.sh`: `SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"`, exported for
  `docker buildx build`; `APK_REFRESH="${APK_REFRESH:-$(date -u +%Y-%m)}"` passed as
  `--build-arg APK_REFRESH=...`; output `--output type=image,push=$PUSH,rewrite-timestamp=true`
  instead of `--push`.
- `scripts/check_reproducible.sh`: manual only, not wired into CI; exit 0 when layers match,
  1 otherwise.
- The `Dockerfile` declares `ARG APK_REFRESH` (by `dev`).

## Steps

- [01 — Reproducible flags in release.sh](scripts/01-release-flags.md)
- [02 — Docker stub and release.bats](scripts/02-release-tests.md)
- [03 — check_reproducible.sh and its tests](scripts/03-check-reproducible.md)

## CI Checks

- `make lint` (CI job: `build-and-test`)
- `make test` (CI job: `build-and-test`) — runs `test/scripts/`

## Notes

- `release.sh`'s design is `automation`'s (see `image-cache-agents.md`); this plan applies it.
