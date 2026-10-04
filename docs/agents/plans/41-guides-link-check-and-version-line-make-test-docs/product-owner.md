# Product Owner Plan: Guides link check and version line (make test-docs)

Main plan: [plan.md](plan.md)

## Shared contracts

- You produce `docs/guides/vault.md` with exactly one line `**Vault version:** 0.0.1`
  (matching `VERSION`; regex `^\*\*Vault version:\*\* [0-9]+\.[0-9]+\.[0-9]+$`).
- `automation`'s `bump_version.sh` / `check_tag_version.sh` rely on that exact format, and
  `make test-docs` must pass on the file: only absolute `https://` links, no images, no
  reference-style links, no relative links to pages that don't exist yet.

## Implementation Steps

### Step 1 — Minimal `docs/guides/vault.md`

Create `docs/guides/vault.md` holding only the top block from
`docs/agents/specs/guides-portability.md` → "Top block": a `# Vault` title (or the title
the spec's `guides-pages.md` implies), a short note to copy the whole `docs/guides/` tree
rather than single pages, where the originals live
(`https://github.com/darthjee/vault/tree/main/docs/guides`), and the version line
`**Vault version:** 0.0.1` on its own line. Nothing else — #42 fills in the rest of the page
(what Vault is, choosing a path, page index). If #42 already landed when this runs, only make
sure the version line is present in the exact format.

### Step 2 — Agent docs

Update `docs/agents/` to describe what #41 adds:

- `folder-structure.md`: add `check_guides_links.sh` to the `scripts/` row and to the
  "Test scripts" bullet; add a `test-docs` row to the Makefile table; extend the
  `bump-version` / `check-version-tag` rows with the guides version line; mention the
  link-check and bump/check bats suites in the `test/scripts/` row; add `docs/guides/` to the
  tree/table if not already present (owner `product-owner`).
- `architecture.md`: add a "Docs" row (`make test-docs`) to the Testing table; mention the
  guides version line where versioning is described.
- `contributing.md` CI Checks table: add a `docs/guides/` → `make test-docs` row, and
  `make test-docs` + `make test` to the `scripts/`, `Makefile` row (the new script has bats
  tests).

## Files to Change

- `docs/guides/vault.md` — new, minimal (top block + version line).
- `docs/agents/folder-structure.md`, `docs/agents/architecture.md`,
  `docs/agents/contributing.md` — document the script, target, CI step and version line.

## CI Checks

- `docs/guides/`: `make test-docs` (CI job: `build-and-test`)

## Notes

- Do not touch `scripts/`, `Makefile`, `.circleci/`, `test/` or root-level files.
- Keep relative links in `docs/agents/` working; that tree is not covered by the link check.
