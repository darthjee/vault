# docker wrapper and test harness

Add the single entry point for docker calls, and the bats harness every later step uses.

- `cli/lib/docker.sh`:
  - `docker_run_cmd <args...>` (or a similar name) calls `command docker "$@"`, so every docker
    call goes through one function;
  - `docker_available` returns 0 when `docker` is on `PATH` (`command -v docker`).
- `test/cli/helpers/docker_stub.bash` (loaded with `load`):
  - creates a temp dir with an executable `docker` stub and puts it first on `PATH`;
  - the stub appends each call's arguments (one call per line, arguments NUL- or
    tab-separated, so values with spaces stay distinct) to a log file under
    `$BATS_TEST_TMPDIR`;
  - scripted output per subcommand via env vars or files (e.g. the `docker info` stdout, its
    exit status, and stderr), with sane defaults: daemon reachable, `runc` only, no rootless;
  - helpers to assert the recorded calls (`assert_docker_called info …`,
    `assert_docker_not_called info`);
  - a helper to run with **no** `docker` on `PATH` (a `PATH` holding only the needed tools).
- Library unit tests source the libraries directly from `cli/lib/`; end-to-end resolution
  tests source `cli/bin/vault` (see step 07).

## Files to Change
- `cli/lib/docker.sh` — new: the docker wrapper and the availability check.
- `test/cli/helpers/docker_stub.bash` — new: the stub `docker` and assertion helpers.
- `test/cli/docker.bats` — new: wrapper forwards args verbatim; availability check.
