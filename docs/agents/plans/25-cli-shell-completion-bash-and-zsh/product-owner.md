# Product-owner Plan: CLI shell completion (bash and zsh)

Main plan: [plan.md](plan.md)

## Shared contracts

Document the behaviour defined in [plan.md → Shared contracts](plan.md#shared-contracts). It is
the source of truth for the spec wording.

## Implementation Steps

### Step 1 — Shell completion spec

In `docs/agents/specs/cli-commands.md → Shell completion`, replace "internals are left to it"
with the settled behaviour:
- the options per command;
- the `--runtime` values, in both forms;
- `--env-file` files, `-v` paths, and `--name` instance names from `docker ps`, quiet on failure;
- `[dir]` directories;
- no completion for passthrough arguments or after `version`/`help`.

Name the bash entry point (`_vault_complete`) and the bash 3.2 constraints.

### Step 2 — Settle open point 8

- `docs/agents/specs/cli-overview.md`, open point 8: mark it **Settled**. `zshusers/zsh:5.9`
  (`ZSH_IMAGE`) runs from `scripts/test.sh` in `make test`. Mark it `#25 (settled)`, as done for
  points 6 and 7.
- `docs/agents/specs/cli-tooling.md`, the zsh row of "Lint and test coverage": replace "runner
  chosen by #25; open point 8" with the image and the script.

## Files to Change

- `docs/agents/specs/cli-commands.md` — Shell completion section.
- `docs/agents/specs/cli-overview.md` — open point 8.
- `docs/agents/specs/cli-tooling.md` — zsh row.

## Notes

- If `automation` pins a different tag than `5.9`, use that tag in the spec.
