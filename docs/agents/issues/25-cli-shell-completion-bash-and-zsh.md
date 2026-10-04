# Issue: CLI shell completion (bash and zsh)

## Description
Part of epic #20 (Vault CLI). Depends on #24 (CLI commands, merged). Owning agent: `cli`. `automation` helps with the zsh syntax-check runner in `scripts/test.sh` (open point 8). Follow `docs/agents/specs/*.md`, mainly [cli-commands.md → Shell completion](../specs/cli-commands.md#shell-completion), [cli-tooling.md](../specs/cli-tooling.md) and [cli-install.md](../specs/cli-install.md).

## Problem
The `vault` CLI has eight subcommands (`up`, `down`, `logs`, `status`, `compose`, `run`, `version`, `help`) and options that depend on the command (see `cli/lib/usage.sh` and `_args_key` in `cli/lib/args.sh`). Without completion, users have to remember them.

## Expected Behavior
- `cli/completion/vault.bash` (bash 3.2 compatible) completes:
  - the subcommands, in the first position;
  - only the options the current subcommand accepts, matching `_args_key`: `--runtime`, `-p`, `-v`, `-e` and `--env-file` for `up`/`run`; `--stop-timeout` for `up`/`run`/`down`; `-f`/`--attach` for `up`; `-f`/`--follow` for `logs`; `--name`, `--image` and `-h`/`--help` for every command except `version`/`help`;
  - the `--runtime` values `auto`, `sysbox` and `privileged`, both as `--runtime <TAB>` and as `--runtime=<TAB>`;
  - file paths for `--env-file`;
  - file and directory paths for the `-v`/`--volume` value (the source part);
  - existing instance names for `--name`: the `vault-*` containers from `docker ps -a`, shown without the `vault-` prefix. If `docker` is missing or fails, nothing is offered, with no error output;
  - directories for the `[dir]` positional;
  - nothing for `--image`, `-p`, `-e` or `--stop-timeout` values;
  - nothing after `version`/`help`, and nothing once the `compose`/`run` passthrough arguments start (after `[dir]` or `--`).
- `cli/completion/_vault`: zsh completion with the same coverage.
- Bats tests under `test/cli/` (so they also run on bash 3.2) call the bash completion function with scripted `COMP_WORDS`/`COMP_CWORD`. They check the subcommands, the options per command, the `--runtime` values, the `--name` instance names (through the stub `docker` on `PATH`, including when docker fails), and that passthrough args get no completion.
- `make test` runs `zsh -n cli/completion/_vault` in a pinned zsh image (e.g. `zshusers/zsh:5.9`). This settles open point 8.
- `make lint` (shellcheck) covers `cli/completion/vault.bash`.
- Out of scope: shipping the completion files in the image and installing them on the host (#26). Release assets (#28).

## Solution
- `cli`: add `cli/completion/vault.bash`, a `complete -F _vault vault` function built on `COMP_WORDS`/`COMP_CWORD`/`compgen` with no bash 4+ features (no `compopt`, no associative arrays, no `_init_completion` from bash-completion). Add `cli/completion/_vault` (`#compdef vault`, built on `_arguments`/`_describe`, with `_files`, `_directories` and a docker-backed `--name` helper).
- `cli`: add `test/cli/completion.bats`.
- `automation`: extend `scripts/test.sh` with the pinned-zsh `zsh -n` step (overridable image variable, like `BATS_IMAGE`).
- Specs: update [cli-commands.md → Shell completion](../specs/cli-commands.md#shell-completion) with the dynamic values (env files, volume paths, instance names) and the passthrough rule. Mark open point 8 settled in `cli-overview.md`, and update the zsh row in `cli-tooling.md`.

## Benefits
- Faster CLI use with fewer typos: subcommands, options, runtime values, instance names and paths are all available with TAB.
- Completion offers only what the parser accepts for the current command.
