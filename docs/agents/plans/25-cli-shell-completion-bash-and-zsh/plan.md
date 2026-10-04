# Plan: CLI shell completion (bash and zsh)

Issue: [25-cli-shell-completion-bash-and-zsh.md](../../issues/25-cli-shell-completion-bash-and-zsh.md)

## Overview

Add `cli/completion/vault.bash` (bash 3.2) and `cli/completion/_vault` (zsh). Both complete the
subcommands, the options each command accepts, the `--runtime` values, file and directory paths,
and the instance names for `--name`. Bats tests under `test/cli/` cover the bash function on both
bats images. `make test` gains a `zsh -n` syntax check of `_vault` in a pinned zsh image, which
settles open point 8. The specs are updated to match.

## Agents involved

- [cli](cli.md)
- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

- **Files:** `cli/completion/vault.bash` and `cli/completion/_vault`, both mode `0644`, not
  executable, not bundled into `build/vault`.
- **bash entry point:** sourcing `vault.bash` only defines functions and runs
  `complete -F _vault_complete vault`. `_vault_complete` reads `COMP_WORDS`/`COMP_CWORD` and fills
  `COMPREPLY`. Tests call it directly.
- **Option table (both shells), from `_args_key` in `cli/lib/args.sh`:**

  | Command | Options |
  |---------|---------|
  | `up` | `--name --image --runtime -p --port -v --volume -e --env --env-file --stop-timeout -f --attach -h --help` |
  | `run` | `--name --image --runtime -p --port -v --volume -e --env --env-file --stop-timeout -h --help` |
  | `down` | `--name --image --stop-timeout -h --help` |
  | `logs` | `--name --image -f --follow -h --help` |
  | `status`, `compose` | `--name --image -h --help` |
  | `version`, `help` | none |

- **Values:**
  - `--runtime`: `auto sysbox privileged`, both as `--runtime <TAB>` and as `--runtime=<TAB>`.
  - `--env-file`: files.
  - `-v`/`--volume`: files and directories.
  - `--name`: the `vault-*` names from
    `docker ps -a --filter name=^vault- --format '{{.Names}}'`, without the `vault-` prefix.
    If `docker` is missing or fails, nothing is offered and nothing goes to stderr.
  - `--image`, `-p`, `-e`, `--stop-timeout`: nothing.
  - `[dir]`: directories.
  - `compose`/`run` passthrough arguments (after `[dir]` or `--`): nothing.
- **zsh check runner:** `ZSH_IMAGE` (default `zshusers/zsh:5.9`), runs
  `zsh -n cli/completion/_vault` from `scripts/test.sh` when the file exists.
