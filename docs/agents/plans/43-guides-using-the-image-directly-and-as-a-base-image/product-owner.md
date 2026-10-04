# Product Owner Plan: Guides: using the image directly and as a base image

Issue: [43-guides-using-the-image-directly-and-as-a-base-image.md](../../issues/43-guides-using-the-image-directly-and-as-a-base-image.md)

## Overview
Add `docs/guides/vault/docker-run.md` and `docs/guides/vault/base-image.md`, following
[guides-pages.md](../../specs/guides-pages.md) and the portability rules in
[guides-portability.md](../../specs/guides-portability.md#portability-rules), then replace the
"not written yet" placeholders in `docs/guides/vault.md` with links and add both pages to its
page index.

## Context
- Epic #39; #42 (index, `concepts.md`, `security.md`) is merged and sets the page style:
  `# Title`, a one-line purpose, then "Back to the [Vault guides index](../vault.md)."
- Source material, checked by hand against the code: README `## Usage` → `### Running`,
  `### Arguments` (→ `docker-run.md`), `### Shipping a stack as its own image`,
  `### Offline preload` (→ `base-image.md`), and README `### Baked images` for
  `vault up --image`. The README itself is **not** changed here (#47 does that).
- Behaviour to describe: `source/bin/entrypoint.sh` (`/vault/images` preload,
  compose passthrough), `source/lib/images.sh`.
- Pages not written yet (`cli.md`, `configuration.md`, `operations.md`,
  `troubleshooting.md`) are named in inline code, never linked; whichever of #44 / #45 lands
  later turns them into links. Existing pages (`concepts.md`, `security.md`, `../vault.md`)
  are linked with relative links.
- Ports: both pages use `-p 8080:80` and say so. Image tags: `darthjee/vault:<version>`;
  `latest` / untagged only in a quick start, said explicitly.

## Steps

- [01 — Write docker-run.md](product-owner/01-write-docker-run.md)
- [02 — Write base-image.md](product-owner/02-write-base-image.md)
- [03 — Link the pages from vault.md and update the spec](product-owner/03-link-from-index.md)

## CI Checks
- `docs/guides`: `make test-docs` (CI job step: "Check guides links")

## Notes
- Do not copy content that belongs to other pages: env var details go to `configuration.md`
  (#45), the shutdown sequence and stop timeouts to `operations.md` (#45), bind mounts and the
  persistence model are already in `concepts.md` (link there).
- Keep commands copy-paste ready and every `docker run` example complete (runtime flag,
  `/vault` mount, data volume, `-p`).
