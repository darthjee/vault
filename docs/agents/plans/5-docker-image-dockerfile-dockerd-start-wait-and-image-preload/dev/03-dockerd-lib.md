# dockerd.sh

Create `source/lib/dockerd.sh` (flow steps 2–3, edge case 3; image.md → Dockerd startup):

- `dockerd_start`: run `dockerd-entrypoint.sh dockerd --host=unix:///var/run/docker.sock` in the background and store its PID in a global (e.g. `DOCKERD_PID`) for `dockerd_stop` and for #6's shutdown path. Pass `dockerd` explicitly as the first argument, so the dind entrypoint doesn't add its default `--host` list (believed to include `tcp://0.0.0.0:2375` when `DOCKER_TLS_CERTDIR` is empty — verified in step 06).
- `dockerd_wait <timeout>`: poll `docker info >/dev/null 2>&1` once per second, up to `<timeout>` seconds. Return 0 on success. On timeout, print the hint `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` to stderr and return 1.
- `dockerd_stop <pid>`: send SIGTERM to the PID (ignore an already-dead process) and `wait` for it, so the daemon exits cleanly before the container does.
- The shared privileges hint (see step 02).

Tests, `test/lib/dockerd.bats` (stub `docker`, `dockerd-entrypoint.sh` and `sleep` as functions so tests are fast):
- `dockerd_start` calls `dockerd-entrypoint.sh` with `dockerd --host=unix:///var/run/docker.sock` and sets the PID.
- `dockerd_wait` succeeds immediately, succeeds after N failed polls, and times out with the hint and status 1 after `<timeout>` polls.
- `dockerd_stop` terminates a background stub process and returns once it has exited.

## Files to Change
- `source/lib/dockerd.sh` — new.
- `test/lib/dockerd.bats` — new.
