# Option parsing

Parse the options of [cli-commands.md → Options](../../../specs/cli-commands.md#options) for a
given command, in bash 3.2.

- `cli/lib/args.sh`, e.g. `args_parse <command> <args...>`:
  - accepts `--opt value`, `--opt=value` and `-x value`;
  - the options valid per command: `--name`, `--image` (all of `up`, `down`, `logs`, `status`,
    `compose`, `run`); `--runtime`, `-p`/`--port`, `-v`/`--volume`, `-e`/`--env`,
    `--env-file` (`up`, `run`); `--stop-timeout` (`up`, `run`, `down`); `-f` = `--attach`
    (`up`) / `--follow` (`logs`); `-h`/`--help` everywhere;
  - repeatable options append to `ARGS_PORTS`, `ARGS_VOLUMES`, `ARGS_ENVS`, `ARGS_ENV_FILES`,
    and record that the flag was given at all (for "flags replace per key");
  - scalars go to `ARGS_NAME`, `ARGS_IMAGE`, `ARGS_RUNTIME`, `ARGS_STOP_TIMEOUT`,
    `ARGS_ATTACH`/`ARGS_FOLLOW`, with an "is set" marker (an empty value is not "unset");
  - positional handling:
    - `up`, `down`, `logs`, `status`: options and one `[dir]` in any order
      (`ARGS_DIR`); a second positional is a usage error;
    - `compose`: parsing stops at the first non-option; it and the rest go to
      `ARGS_PASSTHROUGH`;
    - `run`: the first positional is `[dir]` only if it is an existing directory (open
      point 1), then parsing stops at the next non-option;
    - `--` ends option parsing (everything after it is passthrough for `compose`/`run`,
      or the `[dir]` for the others);
  - validation (exit 2, spec wording): unknown option (+ `run "vault help"` hint), missing
    value (`<option> requires a value`), bad value (`invalid value for <option>: '<value>'`)
    for `--runtime` not in `auto|sysbox|privileged`, `--stop-timeout` not a positive integer,
    and an explicit `--name` not matching `[a-z0-9][a-z0-9_.-]*`.
- `-e` values are never validated nor echoed.

## Files to Change
- `cli/lib/args.sh` — new: option parsing for every command.
- `test/cli/args.bats` — new: both value forms, per-command option sets, repeatable options,
  `--`, `run` `[dir]` rule (existing dir vs. compose arg), each usage error and its message.
