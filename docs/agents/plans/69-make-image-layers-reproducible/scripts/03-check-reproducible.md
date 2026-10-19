# check_reproducible.sh and its tests

Add `scripts/check_reproducible.sh` (manual only; header says it is not run in CI). It computes
one `APK_REFRESH` (same default as `release.sh`) and builds the image twice with `--no-cache`,
`SOURCE_DATE_EPOCH` (default `0`), `rewrite-timestamp=true` and `--load`, into two throwaway
tags (e.g. `vault-repro-check:a` / `:b`), after running `scripts/bundle_cli.sh` if `build/vault`
is missing. It compares `docker image inspect --format '{{json .RootFS.Layers}}'` of the two,
prints `reproducible: N layers identical` or the indexes that differ, removes both tags, and
exits 0 / 1. Optional env: `DOCKER_VERSION`.

Add `test/scripts/check_reproducible.bats` using the docker stub: matching layer lists → exit 0;
differing lists → exit 1 with the differing index named; a failing build → non-zero; both
builds get `--no-cache` and the same `APK_REFRESH`; the tags are removed.

## Files to Change
- `scripts/check_reproducible.sh` — new manual digest check.
- `test/scripts/check_reproducible.bats` — new tests.
- `test/scripts/helpers/docker_stub.bash` — extend to return canned `image inspect` output per tag.
