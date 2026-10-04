# Register the spec in the hub

In `docs/agents/specs.md` → **Active specs**, replace the `| None | — | — |` row with:

```markdown
| [`guides-`](specs/guides-overview.md) | #39 | #48 |
```

Change nothing else in the hub: its precedence, deviation and removal rules already apply to
the guides spec. Keep `docs/agents/specs/.gitkeep` (#48 removes the spec files; the folder
stays).

## Files to Change

- `docs/agents/specs.md` — Active specs row for `guides-`.
