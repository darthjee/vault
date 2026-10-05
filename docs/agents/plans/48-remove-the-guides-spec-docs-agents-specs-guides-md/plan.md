# Plan: Remove the guides spec (docs/agents/specs/guides-*.md)

Issue: [48-remove-the-guides-spec-docs-agents-specs-guides-md.md](../../issues/48-remove-the-guides-spec-docs-agents-specs-guides-md.md)

## Overview
Last sub-issue of epic #39. Move the rules found only in the guides spec (audience, style and page header, inline links and no assets) into `AGENTS.md` → "User guides", point `product-owner` to that section instead of epic #39, then delete the four `docs/agents/specs/guides-*.md` files and their row in the spec hub. Documentation only. Precedent: #30 (PR #51), which removed the CLI spec.

The spec deletion and hub row belong to `product-owner` (`docs/agents/`). `AGENTS.md` and `.claude/agents/product-owner.md` belong to the `architect` (root-level files, `.claude/`), who applies the step below directly, as in #30.

See [product-owner.md](product-owner.md) for the product-owner plan.

## Architect step — move the lasting rules and drop the epic #39 pointer

Do this before the product-owner deletes the spec, so the rules are never only in git history.

1. In `AGENTS.md` → "User guides (`docs/guides/`)", replace the **Portable** bullet and add **Audience** and **Style** right after it. Leave **Versioned**, **Checked** and **Kept current** unchanged:

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

### Files to Change
- `AGENTS.md` — extend **Portable**, add **Audience** and **Style** in "User guides".
- `.claude/agents/product-owner.md` — replace the epic #39 bullet with the pointer to `AGENTS.md`.

## CI Checks
- `docs/guides/`: `make test-docs` (CI job: `build-and-test`). No guide page changes, so it must stay green.

## Notes
- The PR body must include `Closes #39` (in addition to the usual `Fixes #48`) so merging closes the epic.
- Leave the "Specs" row of `AGENTS.md`'s docs table and the `product-owner` scope row ("incl. `specs/`") as they are: the hub and `specs/` stay for future epics.
