# Docker stub and release.bats

Add `test/scripts/helpers/docker_stub.bash`, following `gh_stub.bash`: a `docker` on `PATH`
that appends its arguments (and the `SOURCE_DATE_EPOCH` it saw) to a log and exits with a
configurable status. Add `test/scripts/release.bats` covering: usage without a tag; invalid
`PUSH`; default build passes `--platform linux/amd64,linux/arm64`, both tags,
`--build-arg APK_REFRESH=<current UTC month>`, `--output type=image,push=true,rewrite-timestamp=true`
and `SOURCE_DATE_EPOCH=0`; `PUSH=false` gives `push=false`; `APK_REFRESH`, `SOURCE_DATE_EPOCH`
and `DOCKER_VERSION` overrides are passed through.

## Files to Change
- `test/scripts/helpers/docker_stub.bash` — new docker stub.
- `test/scripts/release.bats` — new tests for `release.sh`.
