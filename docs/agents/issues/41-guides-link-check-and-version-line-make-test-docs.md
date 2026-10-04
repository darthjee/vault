# Issue: Guides link check and version line (make test-docs)

## Description
Part of epic #39 (portable user guides for Vault), sub-issue 2 of 9. Depends on #40 (guides
spec, merged): the contract is fixed in
`docs/agents/specs/guides-portability.md` (sections
"Version line" and "Link check contract"). Agent: `automation`.

## Problem
The guides under `docs/guides/` are copied by hand into other repositories, so their links must
stay portable, and `docs/guides/vault.md` states which Vault version the guides match. Nothing
enforces either today, and the page PRs (#42–#46) need CI to validate them as they land.

## Expected Behavior
### Link check
- New script `scripts/check_guides_links.sh` and Make target `make test-docs`.
- Scope: every `*.md` file under `docs/guides/` (not the README nor `docs/agents/`). The
  script takes an optional root directory (default `docs/guides`) so tests can run it on
  fixture trees.
- Fails (non-zero exit), naming the file and the link, on:
  - a relative link that leaves the guides root;
  - a relative link to a missing file;
  - a link to a missing anchor, in the same page (`#anchor`) or another guide page
    (`cli.md#vaultrc`);
  - a link that is neither relative-inside nor absolute `https://` (e.g. `http://`, absolute
    paths, `file:`, `mailto:`);
  - a reference-style link definition (`[ref]: target`): guides use inline links only;
  - an image link (`![alt](...)`): guides ship no assets.
  All problems are reported in one run, not just the first.
- Anchor slugs follow GitHub: lowercase the heading text, drop punctuation except `-` and `_`,
  spaces to `-`; duplicate headings get `-1`, `-2`, … suffixes.
- Links inside fenced code blocks and inline code are ignored.
- Passes on an empty or missing guides root.
- Plain bash + awk/sed/grep, run on the host (no Docker, no new dependency), compatible with
  bash 3.2 so it also runs on macOS.

### CI
- Its own step `make test-docs` in the CircleCI `build-and-test` job, next to `make lint` /
  `make test`. `make test` is unchanged.

### Version line
- If `docs/guides/vault.md` does not exist yet (#42 not landed), create a minimal one holding
  only the top block from the spec (copy the whole `docs/guides/` tree; originals at
  `https://github.com/darthjee/vault/tree/main/docs/guides`) and the line
  `**Vault version:** X.Y.Z` matching `VERSION`. #42 fills in the rest.
- `scripts/bump_version.sh X.Y.Z` updates that line; it fails before writing anything if the
  file is missing or has zero or several such lines, like the other targets.
- `scripts/check_tag_version.sh` (`make check-version-tag`) validates it against the tag;
  missing file, missing or duplicated line, or mismatch fails. Header comments, messages and
  the CircleCI step name are updated to mention the guides line.

### Tests and lint
- bats tests under `test/scripts/` for the link check, using fixture trees: a passing tree,
  each failure kind (leaving the tree, missing file, missing anchor in same page and other
  page, non-https / absolute path, reference-style definition, image), duplicate-heading
  anchors, links inside code blocks/inline code ignored, empty and missing root.
- New bats suites (none exist today) for `bump_version.sh` and `check_tag_version.sh`, covering
  the existing targets and the guides line
  (updated, missing file, missing/duplicated line, mismatch).
- All new scripts pass `make lint` (shellcheck).

### Out of scope
- No change to existing Make target names or release jobs (the release `check-version-tag`
  job only gains the guides line through the script).
- Guide content beyond the minimal `vault.md` (#42–#46).
