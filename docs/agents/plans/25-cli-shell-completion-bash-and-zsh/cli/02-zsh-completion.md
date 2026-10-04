# zsh completion

Write `cli/completion/_vault` (`#compdef vault`) with the same coverage as the bash file:

- `_arguments -C` with a `1: :->command` state, then `_describe` for the eight subcommands, each
  with its usage.sh description;
- one `_arguments` spec per subcommand, following the option table in
  [plan.md](../plan.md#shared-contracts). Use exclusion groups for the short/long pairs
  (`(-p --port)`, `(-f --attach)`, …), and `*` for the repeatable ones (`-p`, `-v`, `-e`,
  `--env-file`);
- values: `--runtime:(auto sysbox privileged)`, `--env-file:_files`, `-v:_files`,
  `--name:` a helper running the same `docker ps` as bash, prefix stripped, quiet on failure;
  `--image`, `-p`, `-e` and `--stop-timeout` take a free-form value;
- `[dir]`: `_directories`;
- `compose`/`run`: `'*::args: '` after `[dir]`, so nothing is completed for passthrough
  arguments;
- `version`/`help`: no arguments.

zsh's `_arguments` handles `--runtime=<TAB>` when the spec is written as `--runtime=`. Use
`--runtime=-` so both the `=` form and the separate-word form work.

It must pass `zsh -n`. shellcheck does not apply (zsh), so don't add it to lint.

## Files to Change

- `cli/completion/_vault` — new.
