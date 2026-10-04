# Product Owner Plan: Guides: index, concepts and security

Main plan: [plan.md](plan.md)

## Overview
Write the guides entry point and its two foundation pages for epic #39, following
`docs/agents/specs/guides-pages.md` and `docs/agents/specs/guides-portability.md`.

## Context
- #40 merged the spec; #41 merged the link check (`make test-docs`, `scripts/check_guides_links.sh`)
  and a minimal `docs/guides/vault.md` holding only the top block and the version line.
- Content is checked by hand against the README (`## Usage` → `### Ports`, `### Persistence`,
  `### Bind mounts`; `## Behaviour`; `## Supported runtimes and platforms`; `## Security`) and
  `AGENTS.md`. The README is **not** changed here (#47 does that).
- Only `vault.md`, `vault/concepts.md` and `vault/security.md` exist after this issue. Any
  other guide page is named in inline code (e.g. `vault/cli.md`), never linked: the link
  check ignores inline code and fails on relative links to missing files.

## Steps

- [01 — Fill the index page](product-owner/01-index-page.md)
- [02 — Write concepts.md](product-owner/02-concepts-page.md)
- [03 — Write security.md](product-owner/03-security-page.md)
- [04 — Record the unwritten-page rule in the spec](product-owner/04-spec-update.md)

## CI Checks
- `docs/guides/`: `make test-docs` (CI job: `build-and-test`)

## Notes
- Links to anything outside `docs/guides/` (README, Sysbox, Docker docs, Docker Hub) are
  absolute `https://` URLs; between guide pages, relative links only; inline links only, no
  reference-style links, no images.
- Port mappings: `concepts.md` explains host → Vault `80` → inner service
  (`ports: ["80:3000"]`) and says which host mapping its example uses (`-p 8080:80`); it may
  mention that the CLI defaults to `3000:80`.
- Image tags: use `darthjee/vault:<version>` in examples; plain `darthjee/vault` only in a quick
  start, said explicitly.
