# Specs

A spec is a working document for one epic. It lives in [`specs/`](specs/) while the epic is open.

## What a spec is

- **Temporary.** A spec covers one epic only.
- **Written first.** The epic's first sub-issue writes the spec.
- **Removed last.** The epic's last sub-issue moves what stays relevant into the README and the
  agent docs, then deletes the spec files.

## Naming

| Path | Purpose |
|------|---------|
| `docs/agents/specs/<topic>-*.md` | Spec files. One `<topic>` prefix per epic (e.g. the former CLI spec of #20 used the `cli-` prefix). |
| `docs/agents/specs/<topic>-overview.md` | Optional. Indexes the files of that spec. |
| `docs/agents/specs/.gitkeep` | Keeps the folder in git while it holds no spec. |

## Precedence

- **Over the agent docs.** While its epic is open, a spec overrides the other agent docs
  (`AGENTS.md`, `architecture.md`, `flow.md`, …) where they conflict.
- **Over the epic body.** Once merged, a spec also wins over the epic body, which is not kept
  in sync.

Other docs link to this hub instead of restating this rule.

## Deviations

A PR that deviates from a spec updates the spec in the same PR.

## Ownership

`product-owner` owns this hub and everything in [`specs/`](specs/).

## Active specs

The issue that writes a spec adds its row here. The issue that removes the spec deletes the row.

| Prefix | Epic | Removed by |
|--------|------|------------|
