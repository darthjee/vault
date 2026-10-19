# Product-owner Plan: Make image layers reproducible

Main plan: [plan.md](plan.md)

## Shared contracts

- Shared contract change: `SOURCE_DATE_EPOCH = 0` (fixed), replacing `git log -1 --format=%ct`.
- Cache-bust knob: build arg `APK_REFRESH=YYYY-MM` (UTC month by default, overridable).
- Digest check: `scripts/check_reproducible.sh`, manual only.
- Minimum BuildKit/buildx versions: as reported by `automation`.

## Implementation Steps

### Step 1 — Update the image-cache specs

- `docs/agents/specs/image-cache-overview.md`: change the `SOURCE_DATE_EPOCH` shared contract to
  the fixed `0`, with the reason (a per-commit epoch changes every clamped layer on a cache
  miss). Point the Security section's cache-bust note at `APK_REFRESH`.
- `docs/agents/specs/image-cache-reproducible.md`: update the Goal to the fixed epoch; replace
  the "shallow or detached checkout" edge case (git is no longer needed) with a note that the
  image `Created` date is constant; add the monthly-rebuild behaviour to the `apk` and cache-bust
  edge cases; turn **Open decisions** into a **Decisions** table: minimum versions, accept
  index drift + monthly `APK_REFRESH`, build-arg form, digest check is a manual script.
  Change the depth marker to **final**.

## Files to Change

- `docs/agents/specs/image-cache-overview.md` — shared contract, security note.
- `docs/agents/specs/image-cache-reproducible.md` — decisions, edge cases, depth.

## CI Checks

- `make test-docs` (CI job: `build-and-test`) — link check of `docs/agents`.

## Notes

- #70's spec (`image-cache-registry-cache.md`) does not depend on the epoch value; check it for
  references to "last commit" and update any it has.
