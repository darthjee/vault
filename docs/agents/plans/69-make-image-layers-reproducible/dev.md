# Dev Plan: Make image layers reproducible

Main plan: [plan.md](plan.md)

## Shared contracts

- Declare `ARG APK_REFRESH=unset` after `FROM` and before `RUN apk add --no-cache bash`, and
  reference it in that `RUN`. The build scripts pass `YYYY-MM`; the default `unset` keeps a plain
  `docker build` working.
- Layer order from #68 stays as it is: `COPY build/vault` is the last content layer.

## Implementation Steps

### Step 1 — Add the `APK_REFRESH` cache-bust arg

In `Dockerfile`, add `ARG APK_REFRESH=unset` right after `FROM`. Reference it in the `apk` step,
e.g. `RUN echo "apk refresh: ${APK_REFRESH}" && apk add --no-cache bash`, so the value is clearly
part of that layer's cache key. Add a short comment: changing the value (monthly by default,
computed by `scripts/release.sh` / `make build-image`) rebuilds this layer and every later one
to pick up `bash` security fixes. Do not move any other instruction.

## Files to Change

- `Dockerfile` — `ARG APK_REFRESH`, use it in the `apk` `RUN`, comment.

## CI Checks

- `make test-image` (CI job: `build-and-test`)
- `make test-cli-e2e` (CI job: `build-and-test`)

## Notes

- `SOURCE_DATE_EPOCH` does not need an `ARG` in the `Dockerfile`; buildx and BuildKit handle it
  in the exporter.
