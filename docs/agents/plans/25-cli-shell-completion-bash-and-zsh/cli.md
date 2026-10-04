# Cli Plan: CLI shell completion (bash and zsh)

Main plan: [plan.md](plan.md)

## Shared contracts

You produce `cli/completion/vault.bash` (entry point `_vault_complete`, registered with
`complete -F _vault_complete vault`) and `cli/completion/_vault`. Both follow the option table and
the value rules in [plan.md → Shared contracts](plan.md#shared-contracts). `automation` runs
`zsh -n cli/completion/_vault` from `make test`. `make lint` already covers `vault.bash` by path
(`scripts/lint.sh`).

## Steps

- [01 — bash completion](cli/01-bash-completion.md)
- [02 — zsh completion](cli/02-zsh-completion.md)
- [03 — bats tests](cli/03-bats-tests.md)

## CI Checks

- `cli/`, `test/cli/`: `make lint` and `make test` (CircleCI job: `build-and-test`).

## Notes

- Keep the option table consistent with `_args_key`. If the two diverge in the future, the
  tests in step 03 should catch it for bash.
- The `--name` lookup calls `docker` on each TAB. Keep it to one `docker ps` call and silence its
  stderr.
