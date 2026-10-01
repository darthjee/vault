# Entrypoint skeleton

Create `source/bin/entrypoint.sh` (mode 755). It is the only place that reads the environment:

1. `#!/usr/bin/env bash`, `set -euo pipefail`; source `/usr/local/lib/vault/{preflight,dockerd,images}.sh`.
2. `timeout="${VAULT_DOCKERD_TIMEOUT:-30}"`; `preflight_check_timeout "$timeout"` and `preflight_check_privileges` → `exit 1` on failure, before dockerd starts.
3. `dockerd_start`; `dockerd_wait "$timeout"` → on failure, `dockerd_stop "$DOCKERD_PID"` and `exit 1`.
4. `images_load_dir /vault/images` → on failure, `dockerd_stop "$DOCKERD_PID"` and `exit 1`.
5. Placeholder for #6: print a notice that the compose step is not implemented yet (#6), then `wait "$DOCKERD_PID"` so the container keeps running for manual checks.

- **No signal trap** (#6 installs it before the pre-checks).
- With `set -e`, call fallible functions inside `if !` / `||` so the cleanup runs before `exit 1`.
- `entrypoint.sh` has no bats tests (`make test` covers `test/lib/` only); it is covered by `make lint` and the manual run in step 06.

## Files to Change
- `source/bin/entrypoint.sh` — new.
