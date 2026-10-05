# Issue: Remove the guides spec (docs/agents/specs/guides-*.md)

## Description
Last sub-issue of epic #39 (portable user guides for Vault). It depends on #47 (README slim-down and links), which is closed. Owner: `product-owner`. Merging it also closes epic #39.

The guides spec is four files under `docs/agents/specs/`: `guides-overview.md`, `guides-pages.md`, `guides-portability.md` and `guides-readme.md`. Its row is in the "Active specs" table of `docs/agents/specs.md`. The removal of the CLI spec in #30 (PR #51) is the precedent.

## Problem
`docs/agents/specs/guides-*.md` was a working document for epic #39. The guides, the README and the agent docs now describe what was built, so the spec is redundant and may drift. Per the spec hub (`docs/agents/specs.md`), the epic's last sub-issue moves what stays relevant into the agent docs, then deletes the spec files.

Most of the lasting rules are already in the agent docs: portability and the copy unit (`AGENTS.md` → User guides, `folder-structure.md`), the version line (`AGENTS.md`, `architecture.md`, `folder-structure.md`), and the link check contract (`architecture.md`, `folder-structure.md`, `contributing.md`). Some rules are only in the spec: the audience, the style and the page header from `guides-pages.md`, and the "inline links only, no assets" rule from `guides-portability.md`.

## Expected Behavior
- The lasting guide-authoring rules that are only in the spec are moved into `AGENTS.md` → "User guides (`docs/guides/`)" before the deletion (exact text under Solution).
- `.claude/agents/product-owner.md` no longer refers to epic #39. It points to `AGENTS.md` → "User guides" instead.
- The four `docs/agents/specs/guides-*.md` files are deleted. `docs/agents/specs/` stays, with only its `.gitkeep`, as the spec hub requires.
- The `guides-` row is removed from the "Active specs" table in `docs/agents/specs.md`. The table stays, with only its header row, ready for the next epic.
- `grep -r 'specs/guides-' . --exclude-dir=.git` finds nothing, except in this issue's own issue and plan files.
- The PR body includes `Closes #39`, so merging the PR closes the epic.
- Documentation only, with no code or test changes. `make test-docs` still passes.

## Solution
1. In `AGENTS.md` → "User guides (`docs/guides/`)", extend the **Portable** bullet and add **Audience** and **Style** bullets after it. Leave **Versioned**, **Checked** and **Kept current** unchanged:

   ```markdown
   - **Portable:** consumer repositories copy the whole tree. Relative links stay inside
     `docs/guides/`; everything else uses absolute `https://github.com/darthjee/vault/...` URLs.
     Inline links only, and no assets (images, includes) that would have to be copied separately.
   - **Audience:** developers of a consumer project **and** the AI agents working in that repo.
   - **Style:** plain, task-oriented Markdown: short sections, tables for mappings, copy-paste
     ready commands. Every `vault/*.md` page starts with a one-line purpose and a link back to
     `../vault.md`.
   ```

2. In `.claude/agents/product-owner.md`, replace the epic #39 bullet:

   ```diff
   - While epic #39 is open, follow the active guides spec (`docs/agents/specs/guides-*.md`, listed in `specs.md`)
   + Follow the guide rules in `AGENTS.md` → "User guides" (portability, audience, style, version line, link check)
   ```

3. Delete `docs/agents/specs/guides-overview.md`, `guides-pages.md`, `guides-portability.md` and `guides-readme.md`. Keep `docs/agents/specs/.gitkeep`.
4. Remove the `guides-` row from the "Active specs" table in `docs/agents/specs.md` and keep the header row.
5. Check with grep that no reference is left, and run `make test-docs`.
6. Put `Closes #39` in the PR body.

Out of scope: page content and the per-page sub-issue map (the guides and git history keep them), and the spec hub itself (`specs.md` and `specs/.gitkeep`), which stays for future epics.

## Benefits
- A single source of truth for the guides: the guides themselves plus the agent docs.
- No stale spec that overrides the agent docs after the epic closes.
- Closes epic #39.
