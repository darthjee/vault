# Automation Plan: CLI shell completion (bash and zsh)

Main plan: [plan.md](plan.md)

## Shared contracts

`cli` provides `cli/completion/_vault`. You run `zsh -n` on it from `make test`, in the image
`ZSH_IMAGE` (default `zshusers/zsh:5.9`).

## Implementation Steps

### Step 1 — zsh syntax check in scripts/test.sh

- Add `ZSH_IMAGE="${ZSH_IMAGE:-zshusers/zsh:5.9}"` next to `BATS_IMAGE`, and document it in the
  usage header and the numbered list of what the script does.
- When `cli/completion/_vault` exists, after the bats runs:
  `docker run --rm -v "$PWD:/code:ro" -w /code "$ZSH_IMAGE" zsh -n cli/completion/_vault`.
  Echo a `zsh -n ($ZSH_IMAGE): cli/completion/_vault` line first, like `run_bats`. A failure
  sets `status=1` and does not stop the remaining checks.
- Pull the image locally before pinning, to confirm the tag exists and that `zsh` is on its
  `PATH`. If `5.9` is unavailable, pin the closest released 5.x tag and record it in the PR.

### Step 2 — Makefile documentation

If the `Makefile` documents the image variables of `make test` (`BATS_IMAGE`,
`BASH32_TEST_IMAGE`), add `ZSH_IMAGE` the same way. Otherwise, there is nothing to change.

## Files to Change

- `scripts/test.sh` — the `zsh -n` step and the `ZSH_IMAGE` variable.
- `Makefile` — only if it lists the test image variables.

## CI Checks

- `scripts/`: `make lint` and `make test` (CircleCI job: `build-and-test`). The CI machine
  pulls the zsh image, so no config change is needed.

## Notes

- `scripts/lint.sh` already lints `cli/completion/vault.bash` by path. No change is needed there.
