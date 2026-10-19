# Issue: Check links of the agent docs (docs/agents) in CI

## Description
`make test-docs` (`scripts/check_guides_links.sh`) only checks the links of the portable user guides under `docs/guides/`. The agent docs under `docs/agents/` (architecture, flow, folder structure, contributing, specs, issues, plans) are not checked at all, so broken links there go unnoticed.

Surfaced while enhancing #66.

## Problem
The current checker cannot simply be pointed at `docs/agents/`: it requires every relative link to stay inside its `ROOT`, while agent docs legitimately link to files elsewhere in the repository (e.g. `../guides/vault/cli.md`, `../../Dockerfile`, `../../scripts/release.sh`). A dry run of `scripts/check_guides_links.sh docs/agents` today reports 4 false positives, all "relative link leaves the guides tree" for links into `docs/guides/`.

Anchor checks also only work for target pages inside the scanned tree: a link such as `../../README.md#section` from an agent doc would not have its anchor verified.

## Expected Behavior
- `make test-docs` checks the links of every `*.md` under `docs/agents/` (including `issues/` and `plans/`) in addition to `docs/guides/`, and fails CI on any broken link.
- Rules for `docs/agents/`:
  - relative links may point anywhere inside the repository, but must resolve to an existing file or directory;
  - anchors are verified for any `.md` target inside the repository, including pages outside `docs/agents/`;
  - every other link must be an absolute `https://` URL, and image links and reference-style links are not allowed (same as the guides);
  - links inside fenced code blocks and inline code are ignored.
- Rules for `docs/guides/` are unchanged (portable tree: relative links stay inside `docs/guides/`, no images, no reference-style links).
- All problems are reported in one run, one `<file>: <message>: <link>` line each.
- Out of scope: root-level Markdown files (`README.md`, `AGENTS.md`, …).

## Solution
- Extend `scripts/check_guides_links.sh` with an optional bound (e.g. `check_guides_links.sh ROOT [BOUND]`): files are scanned under `ROOT`, relative links must stay inside `BOUND` (defaults to `ROOT`, preserving today's behaviour for the guides). Error messages refer to the bound instead of "the guides tree".
- Parse `.md` targets outside the scanned set on demand so their anchors can be verified.
- `make test-docs` runs the checker twice: `docs/guides` (bound = itself) and `docs/agents` (bound = repository root).
- Rename the CircleCI step "Check guides links" to "Check docs links".
- Keep the script bash 3.2 / POSIX awk compatible.
- Add bats cases in `test/scripts/check_guides_links.bats` for the bound (link outside root but inside bound passes, link leaving the bound fails, anchor into a page outside root is verified).
- Update `docs/agents/architecture.md`, `docs/agents/folder-structure.md`, `docs/agents/contributing.md` and the `automation` / `scripts` agent files to describe the new scope.

## Benefits
- Broken links in the agent docs are caught in CI instead of silently rotting.
- One checker, one set of anchor rules, for both doc trees.
