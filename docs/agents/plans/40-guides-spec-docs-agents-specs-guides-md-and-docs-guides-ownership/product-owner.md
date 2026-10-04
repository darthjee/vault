# Product-owner Plan: Guides spec (docs/agents/specs/guides-*.md) and docs/guides ownership

Main plan: [plan.md](plan.md)

## Shared contracts

- Write exactly the four spec files listed in the main plan; `guides-overview.md` is the index.
- Hub row in `docs/agents/specs.md`: exactly the row given in the main plan (prefix `guides-` linking to `specs/guides-overview.md`, epic #39, removed by #48).
- `architect` updates `.claude/agents/product-owner.md`, `.claude/agents/architect.md` and
  `AGENTS.md` to list `docs/guides/` in your scope; use the same wording in
  `folder-structure.md` and `guides-overview.md`.

## Steps

- [01 — Write the guides spec](product-owner/01-write-guides-spec.md)
- [02 — Register the spec in the hub](product-owner/02-register-in-hub.md)
- [03 — List docs/guides in folder-structure.md](product-owner/03-folder-structure.md)

## CI Checks

- Documentation only. `make lint` (shellcheck, CI job `build-and-test`) is unaffected; run it
  only as a sanity check.

## Notes

- Source of truth for content: epic #39's body (Scope, Portability rules, Versions, Testing
  strategy, Edge cases, Backward compatibility, Split) plus the current README and `AGENTS.md`.
  Once merged, the spec wins over the epic body (see `docs/agents/specs.md`).
- Do not restate the hub's precedence/deviation/removal rules; link to `../specs.md` instead.
- Links inside the spec files are agent docs, not guides: the portability rules do not apply
  to them.
