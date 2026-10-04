# bash completion

Write `cli/completion/vault.bash` (`# shellcheck shell=bash` header, sourcing only defines
functions and calls `complete`). It must be bash 3.2 compatible:

- no `compopt`, no associative arrays, no `mapfile`/`readarray`;
- no `_init_completion`, `_filedir` or any other bash-completion helper;
- `compgen -W`, `compgen -f`, `compgen -d` only.

Logic of `_vault_complete`:

1. Word 1 is the subcommand: offer `up down logs status compose run version help`.
2. After `version`/`help`: offer nothing.
3. Walk the words between the subcommand and `COMP_CWORD`, as `args_parse` does:
   - a value option (`--name --image --runtime -p --port -v --volume -e --env --env-file
     --stop-timeout`) without `=` consumes the next word;
   - the first non-option word is `[dir]`;
   - for `compose`/`run`, `--` or any word after `[dir]` starts the passthrough, and nothing is
     offered from there on.
4. If the previous word is a value option, complete its value (see the shared contract). Handle
   `--runtime=<cur>` too. Bash splits it into `--runtime`, `=`, `<cur>` because `=` is in
   `COMP_WORDBREAKS`, so check whether the previous word is `=` and the word before that is
   `--runtime`. Also handle `--runtime=` arriving as one word.
5. If the current word starts with `-`, offer the options of the subcommand (the table in
   [plan.md](../plan.md#shared-contracts)).
6. Otherwise, before `[dir]` is set, offer directories (`compgen -d`).
7. `--name` helper: `docker ps -a --filter 'name=^vault-' --format '{{.Names}}' 2>/dev/null`,
   strip the `vault-` prefix, and filter with `compgen -W`. If the call fails, return nothing.
   Check `command -v docker` first.

Directory and file results that contain spaces must not break `COMPREPLY`. Read `compgen`
output line by line into the array, not through word splitting.

## Files to Change

- `cli/completion/vault.bash` — new.
