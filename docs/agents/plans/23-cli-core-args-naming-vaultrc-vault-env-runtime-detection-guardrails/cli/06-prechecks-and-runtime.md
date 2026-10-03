# Pre-checks and runtime selection

Implement [cli-commands.md → Runtime selection](../../../specs/cli-commands.md#runtime-selection)
and edge cases 1 and 3.

- `cli/lib/runtime.sh`:
  - `runtime_check_docker`: `docker_available` or `docker not found in PATH`, return 1 (all
    commands but `help` / `version`);
  - `runtime_probe`: **one** `docker info` call, e.g.
    `--format '{{json .Runtimes}}{{"\n"}}{{json .SecurityOptions}}'`; a non-zero exit →
    `cannot reach the Docker daemon` + `is Docker running, and can this user access it?`,
    return 1. Stores whether `sysbox-runc` is listed and whether a security option contains
    `rootless`;
  - rootless → `rootless Docker is not supported` + `see "Supported runtimes" in the README`,
    return 1, for every `--runtime` value;
  - `runtime_select <auto|sysbox|privileged>` sets `RUNTIME_ARGS`:
    - `auto` + sysbox → `--runtime=sysbox-runc`, no message;
    - `auto` without → `--privileged` + the fallback warning (the **only** case that warns);
    - `sysbox` without → `--runtime=sysbox requested but sysbox-runc is not available`,
      return 1;
    - `privileged` → `--privileged`, no message, still after the rootless check.
- Detection reads the JSON text with `grep`/string matching (no `jq`).

## Files to Change
- `cli/lib/runtime.sh` — new: docker presence, daemon probe, rootless, runtime table.
- `test/cli/runtime.bats` — new: docker missing, `docker info` failing, rootless with each
  runtime value, the 5 rows of the runtime table, the warning only on the automatic fallback,
  exactly one `docker info` call.
