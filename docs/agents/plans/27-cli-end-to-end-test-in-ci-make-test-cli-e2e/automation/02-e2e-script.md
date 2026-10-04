# Write scripts/test_cli_e2e.sh
Create an executable `scripts/test_cli_e2e.sh` (`#!/usr/bin/env bash`, `set -euo pipefail`). Model it on
`scripts/test_image.sh`: a usage header comment describing the checks, `cd` to the repo root,
`main` calling small functions, `validate_inputs`, `fail`, and `trap _cleanup EXIT`. It must pass
shellcheck.

Flow:

1. `validate_inputs`: `IMAGE` non-empty, `SMOKE_TIMEOUT` a positive integer,
   `test/fixture/docker-compose.yml` and an executable `build/vault` present.
2. Set up state: `NAME="e2e-$$"`, `CONTAINER="vault-$NAME"`, `VOLUME="vault-$NAME-data"`, a temp
   work dir (`mktemp -d`), and a free localhost port (see Notes in [automation.md](../automation.md)).
3. `cli_up`: `build/vault up --name "$NAME" --image "$IMAGE" --runtime=privileged
   -p "127.0.0.1:$PORT:80" "$PWD/test/fixture"` must exit 0, and the output must contain
   `$CONTAINER started`.
4. `wait_for_http`: poll `curl -fsS http://127.0.0.1:$PORT/` until it succeeds, within
   `SMOKE_TIMEOUT`. Fail early if the container stops running.
5. `cli_status`: `build/vault status --name "$NAME"` exits 0, and its output names `$CONTAINER`
   and `privileged` on the `runtime:` line.
6. `cli_compose_ps`: `build/vault compose --name "$NAME" ps` exits 0, and its output lists the
   fixture's `web` service.
7. `cli_down`: `build/vault down --name "$NAME"` exits 0 and prints
   `$CONTAINER stopped and removed (volume $VOLUME kept)`. Then `docker container inspect
   "$CONTAINER"` must fail (the container is gone) and `docker volume inspect "$VOLUME"` must
   succeed (the volume is kept).
8. `install_cli`: run `HOME="$WORK/home" VAULT_INSTALL_DIR="$WORK/bin" VAULT_IMAGE="$IMAGE"
   bash install.sh`. It must exit 0 and its stdout must contain
   `installed vault $(VERSION) to $WORK/bin/vault`. Then check:
   - `"$WORK/bin/vault" version` prints exactly `vault <VERSION>` (`VERSION` file, whitespace stripped);
   - the file's owner uid equals `id -u` (`stat -c %u` on Linux, falling back to `stat -f %u` on macOS);
   - `$WORK/home/.local/share/vault/completion/vault.bash` and `.../_vault` both exist.
   `install.sh` may warn that the install dir is not in `PATH`; that is expected and not a failure.
9. Print `test-cli-e2e: OK`.

`fail <reason>` prints `test-cli-e2e: FAILED: <reason>` to stderr. If the container exists, it also
dumps `docker logs "$CONTAINER"` between separator lines, as in `test_image.sh`. Then it exits 1.

`_cleanup` (always runs): `docker rm -fv "$CONTAINER"`, `docker volume rm "$VOLUME"` (both
best-effort, with errors silenced), and `rm -rf "$WORK"`.

Print a short `test-cli-e2e: <step>` progress line after each passing check, as `test_image.sh` does.

## Files to Change
- `scripts/test_cli_e2e.sh` — new end-to-end test script (mode 755).
