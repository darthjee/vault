# Register the spec in AGENTS.md (architect)
`AGENTS.md` is a root-level file, so the **architect** does this step, not `product-owner`.
- Add a row to the Documentation table: `[Docker image spec](docs/agents/specs/docker-image/) | Temporary spec for epic #2 (removed by #10).`
- Add a one-line note under the table: "During epic #2, `docs/agents/specs/docker-image/` overrides these docs where they conflict."
- Change nothing else in `AGENTS.md`; the conflicting statements are fixed in #10.

## Files to Change
- `AGENTS.md` — documentation table row and the override note.
