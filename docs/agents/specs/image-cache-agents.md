# Image Cache Spec: Scripts Agent

Part of the image-cache spec; start with [the overview](image-cache-overview.md).
Read by #66 (implemented there). Depth: **final**.

## Goal

Script changes in epic #65 (`scripts/release.sh`, a possible digest-check script, …) have a
dedicated owner from the start. A `scripts` agent owns the repo shell scripts; `automation`
keeps CI, build and the release design.

## The `scripts` agent

| Field | Value |
|-------|-------|
| File | `.claude/agents/scripts.md` |
| Name | `scripts` |
| Tools | `Read, Edit, Write, Bash` |
| Description | `Vault scripts specialist. Use for any task involving the repo shell scripts under scripts/*.sh (build, test, release, version and link-check scripts) or their bats tests under test/scripts/.` |

Same frontmatter (`name`, `description`, `tools`) and sections (*Your scope*, *Stack*,
*Commands*, *Conventions*) as the other agents:

- **Stack:** Bash, `set -euo pipefail`, `shellcheck`, bats on `BATS_IMAGE`.
- **Commands:** `make lint`, `make test`.
- **Conventions:** a Makefile recipe longer than one line moves to `scripts/*.sh`; each script
  starts with a usage header comment.

### Owned paths

- Every top-level `scripts/*.sh`:
  `bump_version.sh`, `bundle_cli.sh`, `check_guides_links.sh`, `check_tag_version.sh`,
  `github_release.sh`, `lint.sh`, `release.sh`, `test.sh`, `test_cli_e2e.sh`, `test_image.sh`.
- `test/scripts/` (the bats tests of those scripts).

Not owned: `scripts/ci/*` (stays with `automation`).

### The path decides the owner

No exceptions. For a script coupled to another agent's domain, the domain agent states what is
needed and reports it; `scripts` implements it.

| Script | Domain agent | Domain agent decides |
|--------|--------------|----------------------|
| `test_image.sh` | `dev` | What the image test asserts. |
| `test_cli_e2e.sh` | `cli` | What the CLI end-to-end test asserts. |
| `bundle_cli.sh` | `cli` | The bundling rule. |
| `release.sh` | `automation` | The release design: platforms, tags, cache and reproducibility flags as fixed by this spec. |

`scripts` owns the file in every row.

## What `automation` keeps

- `.circleci/` (`config.yml`)
- `Makefile`
- `scripts/ci/*`
- `VERSION`
- `DOCKERHUB_DESCRIPTION.md`
- `test/bash32/`
- `build/`
- The release / buildx design.

`automation` delegates changes to `scripts/*.sh` to `scripts`.

## Agent-table scope strings

Used in the agent table of `AGENTS.md` and the roster of `.claude/agents/architect.md`:

| Agent | Scope |
|-------|-------|
| `scripts` | `scripts/*.sh` (not `scripts/ci/`), `test/scripts/` — repo shell scripts and their bats tests |
| `automation` | `.circleci/`, `Makefile`, `scripts/ci/`, `VERSION`, `DOCKERHUB_DESCRIPTION.md`, `test/bash32/`, `build/` — CI, build, release design and publishing |

## Docs that list ownership

| File | Change |
|------|--------|
| `.claude/agents/scripts.md` | New. |
| `.claude/agents/automation.md` | Shrinks to what it keeps; delegates `scripts/*.sh` to `scripts`. |
| `AGENTS.md` | Agent table: add the `scripts` row, shrink `automation`'s. |
| `.claude/agents/architect.md` | Roster: same as `AGENTS.md`. |
| `.claude/agents/dev.md` | *Do NOT touch* / ownership lines; script changes are reported to `scripts`. |
| `.claude/agents/cli.md` | *Do NOT touch* / ownership lines; `scripts/bundle_cli.sh` is owned by `scripts`. |
| `.claude/agents/product-owner.md` | *Do NOT touch* list checked; unchanged in effect. |
| `docs/agents/folder-structure.md` | `scripts/` section and the `test/scripts/` owner column. |

## Edge cases

- **New script.** A new top-level `scripts/*.sh` belongs to `scripts`; a new `scripts/ci/*`
  belongs to `automation`. No per-script exceptions are added.
- **Coupled change.** A change that touches both a domain rule and its script (e.g. a new image
  assertion) is split: the domain agent states the rule, `scripts` edits the file.
- **No behaviour change.** Adding the agent changes no script, `Dockerfile`, Makefile or CI
  behaviour.

## Acceptance criteria

- `.claude/agents/scripts.md` exists with the frontmatter and sections above.
- Every file under `scripts/` and `test/scripts/` is owned by exactly one agent
  (`scripts/*.sh` → `scripts`, `scripts/ci/*` → `automation`), checked by review against
  `ls scripts scripts/ci test/scripts`.
- Every file in [Docs that list ownership](#docs-that-list-ownership) states the same split.
- `make lint` and `make test` stay green.
