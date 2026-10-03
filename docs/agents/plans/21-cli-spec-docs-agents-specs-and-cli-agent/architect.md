# Architect Plan: CLI spec (docs/agents/specs) and cli agent

Main plan: [plan.md](plan.md)

## Shared contracts

- Ownership list and `cli` agent commands exactly as in [plan.md](plan.md) → Shared contracts.
- Override note in `AGENTS.md`, verbatim: "During epic #20, `docs/agents/specs/*.md` overrides
  these docs where they conflict."
- The spec files are written by `product-owner` in `docs/agents/specs/` (six `cli-*.md` files).

## Implementation Steps

### Step 1 — Create the `cli` agent and adjust existing agents
- Create `.claude/agents/cli.md` in the same shape as `dev.md` (frontmatter `name: cli`, a
  description mentioning the Vault CLI, `cli/`, `install.sh` and `test/cli/`/`test/install/`;
  `tools: Read, Edit, Write, Bash`), with: owned paths (`cli/bin/vault`, `cli/lib/*.sh`,
  `cli/completion/*`, root `install.sh` as an explicit exception to architect's root ownership,
  `test/cli/`, `test/install/`); must-not-touch paths per owner (`dev`, `automation`,
  `product-owner`) with the instruction to report needed changes to that owner; conventions
  (bash 3.2 only — no associative arrays, `mapfile`, `${var,,}`, `declare -n`, `[[ -v ]]`;
  `set -euo pipefail` in `bin/vault` only; libraries only define functions, module-prefixed;
  only `bin/vault` reads env and `.vaultrc`; `docker` wrapped for bats stubbing; `.vaultrc`
  never `source`d; the bundling rule; follow `docs/agents/specs/cli-*.md` during epic #20);
  commands `make lint`, `make test`, `make bundle-cli`, `make test-cli-e2e`.
- `dev.md`: narrow `test/` to `test/lib/`, `test/fixture/` and the image tests; add
  `source/bin/install.sh` (in-image install entry); add `cli/`, `install.sh`, `test/cli/`,
  `test/install/`, `test/bash32/` to its do-not-touch list.
- `automation.md`: add `test/bash32/` and `build/` (git-ignored bundle output of
  `scripts/bundle_cli.sh`, `.gitignore` entry added in #22); add `cli/` and `install.sh` to its
  do-not-touch list (it is currently told not to touch `test/` as a whole — narrow that so
  `test/bash32/` is allowed).
- `architect.md`: add `cli` to its agents table and note that root `install.sh` belongs to `cli`.
- `product-owner.md`: if it lists the other agents/scopes, add `cli`.

### Step 2 — Update `AGENTS.md`
- Agents table: add `cli` and update `dev`, `automation`, `architect` scopes.
- Documentation table: add a `specs/` row (`docs/agents/specs/` — CLI spec for epic #20) and the
  override note verbatim.

## Files to Change
- `.claude/agents/cli.md` — new
- `.claude/agents/dev.md` — narrowed `test/` scope, `source/bin/install.sh`
- `.claude/agents/automation.md` — `test/bash32/`, `build/`
- `.claude/agents/architect.md` — `cli` row, `install.sh` exception
- `.claude/agents/product-owner.md` — `cli` mention if agents are listed
- `AGENTS.md` — agents table, `specs/` row, override note

## CI Checks
- No CI job covers these files; `make lint` / `make test` are unaffected.

## Notes
- No `.claude/` settings reference agent names, so adding/narrowing agents breaks no tooling.
