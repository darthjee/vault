# Architect Plan: CircleCI pipeline for PRs: lint, unit tests, build, smoke test

Main plan: [plan.md](plan.md)

## Shared contracts

- **Executor**: `machine: image: ubuntu-2404:current` (replaces `machine: true`).

## Implementation Steps

### Step 1 — Update root-level references to the executor
These are root-level / agent-definition files, outside the specialists' scope:
- `AGENTS.md` (Release (CircleCI) section): change "Docker jobs use `machine: true`" to the `ubuntu-2404:current` machine image.
- `.claude/agents/automation.md`: change "CircleCI (`machine: true` executors for Docker jobs)" to the same machine image.

## Files to Change
- `AGENTS.md` — executor wording in the Release (CircleCI) section.
- `.claude/agents/automation.md` — executor wording in the tech list.

## Notes
- Do not touch the credentials line in `AGENTS.md`. ci.md already overrides it, and #9 handles it.
