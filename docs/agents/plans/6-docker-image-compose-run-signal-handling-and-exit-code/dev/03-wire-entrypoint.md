# Wire the entrypoint
Update `source/bin/entrypoint.sh`:

1. Also source `compose.sh` and `signals.sh` from `$VAULT_LIB_DIR` (with the same `shellcheck source=/dev/null` comments).
2. Call `signals_install` **before** the pre-checks, so a signal at any point is handled (edge case 7).
3. Parse `COMPOSE_UP_ARGS` once: `read -ra COMPOSE_UP_ARGS <<< "${COMPOSE_UP_ARGS:-}"`. This is whitespace split with no quoting; the result is an array that `compose_run` reads.
4. Replace the placeholder (`echo …` + `wait "$DOCKERD_PID"`) with:
   - `cd /vault` (`WORKDIR` already sets it; the explicit `cd` documents it);
   - `compose_run "$@"`;
   - `status="$(compose_wait "$COMPOSE_PID")"` or the return-code form. Avoid a subshell if `wait` must run in the parent shell: `wait` only works on the shell's own children, so call `compose_wait` directly and capture its return code;
   - `signals_ignore` (no teardown from a late signal), then `dockerd_stop "$DOCKERD_PID"` (a no-op if the handler already stopped it);
   - `exit "$status"`.
5. Update the header comment: the entrypoint now also runs compose and handles signals.

Check by hand once: run `make build-image`, then start the image with `--privileged` and a small compose file mounted in `/vault`. Check that `docker stop` exits 0 within the grace period, and that `docker run … vault config` passes its args through to compose.

## Files to Change
- `source/bin/entrypoint.sh` — sources the new libs, installs the traps first, parses `COMPOSE_UP_ARGS`, runs and waits for compose, exits with its code.
