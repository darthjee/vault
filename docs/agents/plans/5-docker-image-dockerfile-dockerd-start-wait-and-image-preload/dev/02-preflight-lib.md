# preflight.sh

Create `source/lib/preflight.sh` (flow step 1, edge cases 1–2):

- `preflight_check_timeout <value>`: accept only `^[1-9][0-9]*$`. Otherwise print to stderr a message naming `VAULT_DOCKERD_TIMEOUT`, the bad value and that a positive integer is expected (e.g. `VAULT_DOCKERD_TIMEOUT must be a positive integer, got: 'abc'`), then return 1. Cases: `30` ok; `0`, `-1`, `abc`, `1.5`, empty → fail.
- `preflight_check_privileges`: `mktemp -d`, `mount -t tmpfs none "$dir"`; on success `umount` it and `rmdir`, then return 0. On failure, `rmdir`, print the hint `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` to stderr, and return 1.
- The hint text is also used by `dockerd.sh` (step 03). Define it once, e.g. a `dockerd_privileges_hint` function in `dockerd.sh` that both call (the entrypoint sources both libraries; `preflight.bats` sources both too). Or pick another single-source approach.

Tests, `test/lib/preflight.bats` (stub `mount` / `umount` as bash functions):
- timeout: valid and invalid values, checking the message and status.
- privileges: `mount` succeeds → 0 and `umount` called; `mount` fails → 1, the hint is printed, and the temp dir is removed.

## Files to Change
- `source/lib/preflight.sh` — new.
- `test/lib/preflight.bats` — new.
