# Plan: Remove the CLI spec (docs/agents/specs)

Issue: [30-remove-the-cli-spec-docs-agents-specs.md](../../issues/30-remove-the-cli-spec-docs-agents-specs.md)

## Overview
Delete the epic #20 CLI spec (`docs/agents/specs/cli-*.md`) and keep `docs/agents/specs/` as a generic home for future per-epic specs. A new hub, `docs/agents/specs.md`, explains what a spec is and lists the active ones. Every reference to the CLI spec becomes a generic reference to the hub. `product-owner` owns the `docs/agents/` changes. `architect` owns `AGENTS.md` and `.claude/agents/`, and is included here as an implementer even though it is the coordinator, because those files are its own.

## Agents involved

- [product-owner](product-owner.md)
- [architect](architect.md)

## Shared contracts

- **Hub path:** `docs/agents/specs.md`. Links from `AGENTS.md` use `docs/agents/specs.md`, and links from `.claude/agents/*.md` use `../../docs/agents/specs.md`.
- **Spec folder:** `docs/agents/specs/`, kept in git by `docs/agents/specs/.gitkeep` while it holds no spec.
- **Spec naming:** `docs/agents/specs/<topic>-*.md`, one prefix per epic.
- **Generic description**, to use in docs tables (`AGENTS.md`, `architect.md`): "Spec hub: what a spec is, naming, precedence, and the list of active specs (`specs/`)."
- **Precedence rule:** while its epic is open, a spec overrides the other docs where they conflict. This rule lives only in the hub. Other docs link to the hub instead of restating the rule with an epic number.
- **Ownership:** `product-owner` owns `docs/agents/specs.md` and `docs/agents/specs/`.
- **Acceptance grep:** after both agents finish, this command prints nothing:
  `grep -rn 'cli-\*\.md\|cli-overview\|cli-commands\|cli-config\|cli-install\|cli-tooling\|cli-ci\|epic #20' . --exclude-dir=.git --exclude-dir=issues --exclude-dir=plans`
