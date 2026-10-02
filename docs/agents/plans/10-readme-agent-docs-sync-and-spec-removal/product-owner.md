# Product Owner Plan: README, agent docs sync and spec removal

Main plan: [plan.md](plan.md)

## Shared contracts

- Read from `docs/agents/specs/docker-image/` but do **not** delete it, and do not link to it from new content. The architect deletes it last.
- Keep file names and the `## Configuration` / `## Runtime requirements` headings in `architecture.md`. Link to the README Security section as `../../README.md#security`.
- Describe the entrypoint flow, libraries and Makefile targets / variables exactly as listed in [plan.md → Shared contracts](plan.md#shared-contracts).
- The implementation wins over the spec where they disagree.

## Steps

- [01 — Update flow.md](product-owner/01-update-flow.md)
- [02 — Update architecture.md](product-owner/02-update-architecture.md)
- [03 — Update folder-structure.md](product-owner/03-update-folder-structure.md)

## CI Checks

None. Only Markdown under `docs/agents/` changes; no CI job covers it.

## Notes

- Do not carry over the spec's sub-issue map, conflicts table, alternatives or "Writing rule". They only applied while the epic was in progress.
- Do not touch the issue/plan naming wording in `docs/agents/*.md` unless you find a stale `<issue_id>_<issue_name>.md` there (the architect fixes `AGENTS.md` and `.claude/agents/product-owner.md`).
- `contributing.md` → CI Checks already matches the implementation; leave it unless you find drift.
