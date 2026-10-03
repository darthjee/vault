# Product Owner Plan: CLI spec (docs/agents/specs) and cli agent

Main plan: [plan.md](plan.md)

## Shared contracts

- Write exactly six flat files in `docs/agents/specs/`: `cli-overview.md`, `cli-commands.md`,
  `cli-config.md`, `cli-install.md`, `cli-tooling.md`, `cli-ci.md`.
- The agent ownership section of `cli-overview.md` must match the ownership list in
  [plan.md](plan.md) → Shared contracts (the `architect` agent writes the same list into
  `.claude/agents/*.md` and `AGENTS.md`).
- The bundling rule (`# BEGIN LIBS` … `# END LIBS`, `scripts/bundle_cli.sh` → `build/vault`)
  is written in `cli-tooling.md`.

## Implementation Steps

### Step 1 — Gather the source material
Read the issue file and the body of epic #20 (`gh issue view 20 --repo darthjee/vault`) and the
sub-issues #22–#30 titles (`gh issue view <n>`), so the spec records every decision from #20
(language and bash 3.2 target, command surface, volumes and config, the 14 edge cases, runtime
and guardrails, release and CI, repo layout, testing strategy). Where #20 and issue #21 disagree,
issue #21's "Contracts fixed by this issue" wins.

### Step 2 — Write the six spec files
Following the issue's "Spec files" table and sections:
- `cli-overview.md`: goals; principles (bash 3.2, config never `source`d, never escalate
  privileges silently, summary of the privilege model); source, bundle and in-image paths;
  agent ownership; the backward-compatibility statement; sub-issue map (#22–#30 → spec
  sections/files); **Open points** (each naming the sub-issue that settles it); **Future work**
  list; a note that the spec is a working document (deviating PRs update it; #30 deletes it).
- `cli-commands.md`: every command and flag with defaults; instance naming and sanitizing;
  runtime selection and guardrails; a dedicated privilege-model section; diagnostics format and
  exit codes; the messages table (draft wording from the issue); the 14-case edge-case table
  from #20 with an **Implemented in** column (#23 / #24 / #26); performance notes (`docker info`
  only for `up`/`run`, detached `up`, stop timeout 60 s); secrets never printed.
- `cli-config.md`: `.vaultrc` format, full key list, parsing rules, precedence (flags replace
  per list key), `.vault.env` handling, parsing errors and their messages.
- `cli-install.md`: in-image paths table; install entry contract (`/install` bind mount,
  `--user "$(id -u):$(id -g)"`, no root/`--privileged`/`dockerd`); `install.sh` env vars
  (`VAULT_VERSION`, `VAULT_INSTALL_DIR`, `VAULT_IMAGE`), defaults and behaviour; completion file
  locations; install messages.
- `cli-tooling.md`: `VAULT_VERSION="X.Y.Z"` line and version checks (`bump_version.sh`,
  `check_tag_version.sh`); bundling rule; Make targets table (`bundle-cli`, `test` with
  `BASH32_TEST_IMAGE` from `test/bash32/Dockerfile`, `test-cli-e2e`, `github-release TAG=x`);
  lint/test coverage; testing strategy (stub `docker`, e2e flow).
- `cli-ci.md`: PR pipeline changes; where `test-cli-e2e` runs; the `github-release` job after
  `build-and-release` in context `github` with `GITHUB_TOKEN`; released assets (`vault`,
  `install.sh`, `vault.bash`, `_vault`, `SHA256SUMS`); a failure there never unpublishes the image.

Also add a `docs/agents/specs/` row to `docs/agents/folder-structure.md` if it lists the
`docs/agents/` subfolders.

## Files to Change
- `docs/agents/specs/cli-overview.md` — new
- `docs/agents/specs/cli-commands.md` — new
- `docs/agents/specs/cli-config.md` — new
- `docs/agents/specs/cli-install.md` — new
- `docs/agents/specs/cli-tooling.md` — new
- `docs/agents/specs/cli-ci.md` — new
- `docs/agents/folder-structure.md` — mention `specs/` (temporary, epic #20)

## Notes
- Documentation only; no tests. Keep wording precise: later sub-issues' tests assert the
  spec's message wording.
- Items left to sub-issues (lib file names, test case lists, exact recipes/YAML, README prose,
  completion internals) must not be decided here.
