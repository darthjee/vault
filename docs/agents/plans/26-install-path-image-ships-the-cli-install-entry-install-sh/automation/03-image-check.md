# Image check: the CLI and the install entry
This covers the issue's "`dev` bats or smoke check that the image contains the CLI". It lives in
`scripts/test_image.sh`, which `automation` owns. Add a function `assert_cli_shipped` that runs
before the compose smoke test (it does not need `--privileged` or the running container):

- `docker run --rm --entrypoint vault "$IMAGE" version` prints exactly `vault $(cat VERSION)`;
- `docker run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install -v "<tmp>:/install" "$IMAGE"`
  exits 0 with no output, and `<tmp>/vault` (executable), `<tmp>/completion/vault.bash` and
  `<tmp>/completion/_vault` exist;
- the temp dir is removed in `_cleanup` (extend the trap).

Use the existing `fail` helper for messages (`test-image: FAILED: ...`) and print
`test-image: CLI shipped` on success. Update the header comment.

## Files to Change
- `scripts/test_image.sh` — add the CLI / install-entry assertions.
