# Cross-links from existing pages
Replace every "`cli.md` (not written yet)" mention with a real relative link and list the page
in the index, then run `make test-docs`.

- `vault.md`: link `vault/cli.md` in the "Choosing a path" table and add a row to the page
  index.
- `docker-run.md` ("The CLI alternative") and `base-image.md` (baked images paragraph): link
  `cli.md` (and `cli.md#baked-images` where it fits).
- Run `make test-docs` and fix any broken link or anchor.

## Files to Change
- `docs/guides/vault.md` — link `vault/cli.md`; page index row.
- `docs/guides/vault/docker-run.md` — link `cli.md`.
- `docs/guides/vault/base-image.md` — link `cli.md`.
