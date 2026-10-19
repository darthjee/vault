# Reproducible flags in release.sh

Set `SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"` and export it so `docker buildx build`
forwards it. Compute `APK_REFRESH="${APK_REFRESH:-$(date -u +%Y-%m)}"` and always add
`--build-arg "APK_REFRESH=$APK_REFRESH"`. Replace the `--push` flag with
`--output "type=image,push=$PUSH,rewrite-timestamp=true"` (`PUSH` is already validated as
`true`/`false`). Update the usage header to document `SOURCE_DATE_EPOCH` and `APK_REFRESH`, and
add both to the `echo "release: building ..."` line.

## Files to Change
- `scripts/release.sh` — epoch, `APK_REFRESH` build arg, `--output` with `rewrite-timestamp`, header.
