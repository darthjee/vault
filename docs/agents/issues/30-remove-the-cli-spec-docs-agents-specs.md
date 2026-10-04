# Issue: Remove the CLI spec (docs/agents/specs)

## Description
Part of epic #20 (Vault CLI), and its **last** sub-issue. It depends on #29 (CLI user docs and agent docs sync), which is merged. Agents: `product-owner` (`docs/agents/`) and `architect` (`AGENTS.md`, `.claude/agents/`).

## Problem
`docs/agents/specs/cli-*.md` (overview, commands, config, install, tooling, ci) was a temporary working document for epic #20. Now that the README and the agent docs describe what was built, the spec is redundant and may drift. Several docs and agent definitions still tell agents that the CLI spec overrides the other docs.

The `specs/` folder itself is still useful: later epics (e.g. #39, via #40 and its `guides-*.md` spec) will use it for their own temporary specs. So the CLI content goes, but the folder stays as a generic home for specs, with a hub page that explains it.

## Expected Behavior
- Delete `docs/agents/specs/cli-*.md`. Keep the `docs/agents/specs/` folder, tracked with a `.gitkeep` while it has no spec files.
- Add `docs/agents/specs.md`, the hub for current and future specs. It explains:
  - what a spec is: a temporary working document for one epic, written by the epic's first sub-issue and removed by its last;
  - naming: `docs/agents/specs/<topic>-*.md`, with one prefix per epic (e.g. the former `cli-*.md`);
  - precedence: while its epic is open, a spec overrides the other docs where they conflict, and a PR that deviates from it updates it in the same PR;
  - ownership: `product-owner`;
  - a list of active specs (currently none), which each new spec adds itself to and its removal issue takes out.
- Replace the CLI-spec references with generic ones:
  - `AGENTS.md`: the `Specs` row in the docs table links to `docs/agents/specs.md` with a generic description. Remove the "During epic #20 ... overrides these docs" note (the precedence rule now lives in the hub). Keep "(incl. `specs/`)" in the `product-owner` scope row.
  - `docs/agents/folder-structure.md`: the `docs/agents/` row describes `specs/` generically (temporary per-epic specs, see `specs.md`), without epic #20 or #30.
  - `.claude/agents/architect.md`: the `Specs` row links to the hub with a generic description.
  - `.claude/agents/product-owner.md`: the `specs/` bullet becomes generic and mentions `specs.md`.
  - `.claude/agents/cli.md`, `automation.md`, `dev.md`: remove the "During epic #20, follow `docs/agents/specs/cli-*.md`" lines. `cli.md` keeps `docs/agents/` (including `docs/agents/specs/`) in its "owned by product-owner" list.
- Outside `docs/agents/issues/` and `docs/agents/plans/` (historical records, left as they are), `grep -rn 'cli-\*\.md\|cli-overview\|cli-commands\|cli-config\|cli-install\|cli-tooling\|cli-ci\|epic #20' . --exclude-dir=.git --exclude-dir=issues --exclude-dir=plans` finds no reference to the CLI spec.
- Documentation only, with no tests.
