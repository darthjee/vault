# Plan: Check links of the agent docs (docs/agents) in CI

Issue: [72-check-links-of-the-agent-docs-docs-agents-in-ci.md](../../issues/72-check-links-of-the-agent-docs-docs-agents-in-ci.md)

## Overview

Extend `scripts/check_guides_links.sh` with an optional `BOUND` argument so relative links may leave the scanned `ROOT` while staying inside `BOUND`. Anchors are verified on any `.md` target inside the bound, including pages outside the scan, which are parsed on demand. `make test-docs` then checks `docs/guides/` with today's rules and the whole of `docs/agents/` bounded to the repository root. The CircleCI step is renamed, and the docs describing `test-docs` are updated.

## Agents involved

- [scripts](scripts.md)
- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

- **Interface:** `scripts/check_guides_links.sh [ROOT [BOUND]]`
  - `ROOT` defaults to `docs/guides`. `BOUND` defaults to `ROOT`, so a call with only `ROOT` (and the no-argument call) behaves exactly as today.
  - `ROOT` must be `BOUND` itself or inside it. Otherwise the script prints `test-docs: ROOT must be inside BOUND` on stderr and exits 1.
  - Files scanned: every `*.md` under `ROOT` (`issues/` and `plans/` included when `ROOT` is `docs/agents`).
  - Relative links resolve against the linking file and must stay inside `BOUND`. The message is `relative link leaves the bound` (the old "leaves the guides tree" wording goes). They must point to an existing file or directory (`missing file`).
  - Anchors are checked for every `.md` target inside `BOUND`. A target outside `ROOT` is parsed on demand (same GitHub slug rules).
  - External links: `https://` only. Images and reference-style links still fail. Code is still ignored. Same rules for both trees.
  - Output is unchanged: one `<file>: <message>: <link>` line per problem on stderr and exit 1, otherwise `test-docs: OK (<n> file(s))` on stdout. `<file>` stays relative to `ROOT`.
- **Make target:** `make test-docs` runs
  - `scripts/check_guides_links.sh` (guides, unchanged)
  - `scripts/check_guides_links.sh docs/agents .` (agent docs, bounded to the repo root)

  It prints two `OK` lines. The paths are relative to the repo root, where `make` runs.

## Notes

- Root-level files owned by `architect` also mention the `test-docs` scope: `AGENTS.md` (the `make test-docs` lines, "link check of `docs/guides/`") and `.claude/agents/automation.md` (the `make test-docs` comment) / `.claude/agents/scripts.md` (the `check_guides_links.sh` line). The coordinator updates them to "link check of `docs/guides/` and `docs/agents/`" when integrating.
- A dry run today (`scripts/check_guides_links.sh .`) passes on all 38 Markdown files. The only failures with `ROOT=docs/agents` and no bound are the 4 links into `../guides/vault/`, so no existing doc should need fixing.
- From now on, plans and issue files are link-checked. A plan must not link to a file it intends to create; it should name such files in inline code. This plan follows that rule.
- Out of scope: root-level Markdown files (`README.md`, `AGENTS.md`, …).
