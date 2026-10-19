# Architect Plan: Write the image-cache spec and add the scripts agent

Main plan: [plan.md](plan.md)

## Shared contracts

Implement the **Scripts agent** contract from [plan.md](plan.md#shared-contracts) exactly — name, description, tools, owned paths, the "path decides the owner" rule, what `automation` keeps, and the agent-table scope strings. `product-owner` writes the same contract into `docs/agents/specs/image-cache-agents.md`.

## Steps

- [01 — Add the scripts agent](architect/01-add-scripts-agent.md)
- [02 — Shrink automation and update the other agents](architect/02-update-other-agents.md)
- [03 — Update the agent tables](architect/03-agent-tables.md)

## CI Checks

- `make lint`, `make test` (CI job: `build-and-test`) — must stay green (no code changes).

## Notes

- `architect` is the coordinator, but it owns `.claude/` and root-level files (`AGENTS.md`), so it implements this part itself — as in #21, where the `cli` agent was added by `architect`.
- Ownership check for review: `ls scripts scripts/ci test/scripts` — every entry maps to exactly one agent, and no *Do NOT touch* list contradicts it.
- Out of scope: changing any script's behaviour.
