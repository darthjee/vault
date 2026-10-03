# Container arguments and bin/vault wiring

Tie it together: one function resolves everything and builds the `docker run` argument list
for `up` and `run`, so #24 only executes it.

- `cli/lib/container.sh`, e.g. `container_build_args <command>` fills `CONTAINER_ARGS` in the
  order of [cli-commands.md → Container arguments](../../../specs/cli-commands.md#container-arguments):
  runtime, `--stop-timeout`, `-v <dir>:/vault` (unless `--image` without `[dir]`),
  `-v vault-<name>-data:/var/lib/docker`, extra `-v`, `-p`, `.vault.env` / `--env-file` / `-e`,
  then (`up`) `--name vault-<name>` and `-d` unless attached, then the image and (`run`) the
  passthrough args. `run` gets `--rm` and no `--name`. The `[dir]` mount uses an absolute path.
  If the order changes, list it as a deviation in the PR.
- `cli/bin/vault`:
  - a resolution function (e.g. `vault_resolve <command> <args...>`) that is the only place
    reading `PWD`, `DOCKER_HOST`, `.vaultrc` (`config_parse "$dir" < "$dir/.vaultrc"` when it
    exists) and testing for `.vault.env`. Order: `args_parse` → `.vaultrc` → merge → naming →
    `runtime_check_docker` → (`up`/`run`) `runtime_probe` + rootless + `runtime_select` →
    guardrails → `container_build_args` (per the spec's pre-check order);
  - make the script sourceable for tests: run `vault_main "$@"` only when executed, not
    sourced (`if [ "${BASH_SOURCE[0]}" = "$0" ]`), keeping `# BEGIN LIBS` … `# END LIBS`
    intact so the bundle still works;
  - `vault_main` keeps dispatching only `version` / `help`; no new command.
  - `[dir]` given but missing is #24's message (edge case 8); here, resolve it to an absolute
    path only when it exists.
- Tests source `cli/bin/vault` (and `build/vault`) and call the resolution function with the
  stub `docker`, asserting the exact `CONTAINER_ARGS` list.

## Files to Change
- `cli/lib/container.sh` — new: the `docker run` argument builder.
- `cli/bin/vault` — resolution function, sourceable guard, library block lists the new libs.
- `test/cli/resolve.bats` — new: full argument lists for `up` / `run` across flags, `.vaultrc`,
  `.vault.env`, `--image` with and without `[dir]`, attach, runtime outcomes; `.vaultrc`
  guardrail hits exit 2; edge case 14 (no version check); runs against the source tree and
  the bundle.
- `test/cli/vault.bats` — keep passing (sourceable guard must not change `version` / `help`).
