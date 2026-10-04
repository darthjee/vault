# Plan: Guides link check and version line (make test-docs)

Issue: [41-guides-link-check-and-version-line-make-test-docs.md](../../issues/41-guides-link-check-and-version-line-make-test-docs.md)

## Overview

Add `scripts/check_guides_links.sh` + `make test-docs` (run as its own step in the CircleCI
`build-and-test` job) to enforce the guides portability rules, and add the
`**Vault version:** X.Y.Z` line of `docs/guides/vault.md` to `scripts/bump_version.sh` and
`scripts/check_tag_version.sh`. Since #42 has not landed, a minimal `docs/guides/vault.md`
(top block + version line only) is created here. Contract source:
`docs/agents/specs/guides-portability.md` ("Top block", "Version line", "Link check contract").

## Agents involved

- [product-owner](product-owner.md) — minimal `docs/guides/vault.md`; agent docs under `docs/agents/`.
- [automation](automation.md) — link-check script, Make target, CI step, bump/check version
  scripts, bats tests.

Root-level docs (coordinator / architect, done while integrating the PR):
`AGENTS.md` (Release/versioning bullets, PR job list, Makefile target list: add
`test-docs` and the guides version line), `README.md` Development block (add
`make test-docs  # check links in docs/guides/`), `.claude/agents/automation.md` (owns
`scripts/check_guides_links.sh`, `make test-docs`; PR job list; tag must also match the guides
version line).

## Shared contracts

- **File:** `docs/guides/vault.md` (owned by `product-owner`).
- **Version line:** exactly one line, matched by the regex
  `^\*\*Vault version:\*\* [0-9]+\.[0-9]+\.[0-9]+$`, literal form
  `**Vault version:** 0.0.1` (current `VERSION`). No trailing text on that line.
- `bump_version.sh` rewrites only that line; `check_tag_version.sh` reads the version from it.
  Both treat a missing file, zero lines or more than one line as an error.
- **Links in `vault.md`** must pass `make test-docs`: the originals URL is the absolute
  `https://github.com/darthjee/vault/tree/main/docs/guides`; no relative links to pages that
  don't exist yet (#42 adds the page index).
- **Link-check CLI:** `scripts/check_guides_links.sh [ROOT]`, `ROOT` defaults to
  `docs/guides` (relative to the repo root). Prints one `<file>: <message>: <link>` line per
  problem on stderr, exits 1 if any, prints `test-docs: OK (<n> file(s))` and exits 0 otherwise
  (including empty/missing root).
