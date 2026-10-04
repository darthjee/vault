# Guides Spec: Portability

Part of the [guides spec](guides-overview.md). Fixes the rules that keep the guides working
once copied, the version line and the link check.

## Portability rules

- **Between guide pages:** relative links only (`vault/cli.md`, `../vault.md`,
  `cli.md#vaultrc`). Every relative link resolves to a file inside `docs/guides/`, anchors
  included.
- **Anything outside `docs/guides/`** (the Vault README, the `install.sh` release URL, Docker
  Hub, Sysbox, Docker docs): absolute `https://` URLs only. No relative link leaves
  `docs/guides/`.
- **No links into the consumer repo's own files:** the guides can't know its layout.
- **No assets** (images, includes) that would need to be copied separately.
- **Copy unit:** the whole `docs/guides/` tree (`vault.md` + `vault/`).

## Top block

The top of `docs/guides/vault.md` says:

- copy the whole `docs/guides/` tree, not single pages;
- where the originals live, as an absolute GitHub URL
  (`https://github.com/darthjee/vault/tree/main/docs/guides`);
- which Vault version the guides match (the [version line](#version-line)).

## Version line

- Exact format, on its own line near the top of `docs/guides/vault.md`:

  ```markdown
  **Vault version:** X.Y.Z
  ```

- Exactly one such line; `X.Y.Z` matches `VERSION`.
- `scripts/bump_version.sh X.Y.Z` updates it, like the README `**Current Version:**` line.
- `scripts/check_tag_version.sh` (`make check-version-tag`) validates it against the tag.
- Added by #41 (see [open point 4](guides-overview.md#open-points)).

## Link check contract

Added by #41.

| Item | Contract |
|------|----------|
| Script | `scripts/check_guides_links.sh [ROOT]` (`ROOT` defaults to `docs/guides`). |
| Make target | `make test-docs`. |
| CI | CircleCI PR pipeline, its own `make test-docs` step in job `build-and-test`, alongside `make lint` / `make test`. |
| Scope | Every `*.md` file under `docs/guides/`. |

The check fails on:

- a relative link that leaves `docs/guides/`;
- a relative link to a missing file;
- a link to a missing anchor (in the same page or another guide page);
- a link that is neither relative-inside nor absolute `https://` (e.g. `http://`, absolute
  paths, `file:`).

Rules:

- **Anchor slugs** follow GitHub: lowercase the heading text, drop punctuation except `-` and
  `_`, replace spaces with `-`; duplicate headings get `-1`, `-2`, … suffixes.
- **Code blocks are ignored:** links inside fenced code blocks and inline code are not checked.
- The check covers inline links (`[text](target)`). Reference-style link definitions
  (`[ref]: target`) and images (`![alt](...)`) fail the check: guides use inline links only
  and ship no assets.
- All problems are reported in one run (`<file>: <message>: <link>` on stderr); an empty or
  missing root passes.
- Version line: covered by `check-version-tag` and the bump script tests, not by the link check.

## Edge cases

- **Copied elsewhere:** a consumer may copy the tree somewhere other than `docs/guides/`.
  Since links stay relative inside the tree, any location works as long as the tree is copied
  whole.
- **Heading renames:** anchor links (`cli.md#vaultrc`) must survive heading renames; the link
  check validates anchors, so a rename that breaks a link fails CI.
