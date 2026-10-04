# Write the spec hub
Create `docs/agents/specs.md`, the single place that explains specs. Write it in English with short sections and tables, following the style of the other `docs/agents/*.md` files. Base the "Status of this document" rules on the former `cli-overview.md`, but write them generically:

- **What a spec is:** a temporary working document for one epic. The epic's first sub-issue writes it, and its last sub-issue removes it once the README and the agent docs cover what was built.
- **Naming:** `docs/agents/specs/<topic>-*.md`, one prefix per epic (e.g. the former `cli-*.md` for epic #20). An optional `<topic>-overview.md` indexes that spec's files.
- **Precedence:** while its epic is open, a spec overrides the other agent docs (`AGENTS.md`, `architecture.md`, `flow.md`, …) where they conflict. It also wins over the epic body, which is not kept in sync.
- **Deviations:** a PR that deviates from a spec updates the spec in the same PR.
- **Ownership:** `product-owner`.
- **Active specs:** a table with columns Prefix | Epic | Removed by. It is empty now ("None"). The issue that writes a spec adds its row, and the issue that removes the spec deletes it.

Do not mention epic #20 except as the naming example.

## Files to Change
- `docs/agents/specs.md` — new spec hub.
