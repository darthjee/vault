# Index and cross-references
Wire the new pages into the guides so no "not written yet" mention remains.

- `vault.md` page index: add one row each for `configuration.md`, `operations.md`,
  `troubleshooting.md`.
- Turn every inline-code mention of the three pages into a relative link and drop the
  "(not written yet)" notes:
  - `docker-run.md` (~lines 96, 152), `base-image.md` (~129), `cli.md` (~310, 316, 332),
    `concepts.md` (~97), `security.md` (~57). Re-grep for `configuration.md`, `operations.md`,
    `troubleshooting.md` and `not written yet` across `docs/guides/` to catch any others.
- Leave `examples.md` / `agents-snippet.md` mentions (if any) as inline code — #46 writes them.
- Run `make test-docs` and fix any failure.

## Files to Change
- `docs/guides/vault.md` — page index rows.
- `docs/guides/vault/docker-run.md`, `base-image.md`, `cli.md`, `concepts.md`, `security.md` —
  inline mentions → relative links.
