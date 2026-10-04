# Link-check script

Create `scripts/check_guides_links.sh` (`#!/usr/bin/env bash`, `set -euo pipefail`, header
usage comment like the other scripts, `ROOT` resolved from `BASH_SOURCE`).

Behaviour (contract: `docs/agents/specs/guides-portability.md` → "Link check contract"):

- Argument: optional guides root, default `$ROOT/docs/guides`. Missing dir or no `*.md` files
  → print `test-docs: OK (0 file(s))`, exit 0.
- Collect every `*.md` under the root (`find … -name '*.md' | sort`).
- For each file, with awk:
  - track fenced code blocks (lines starting with ```` ``` ```` or `~~~`) and skip their content;
    strip inline code spans (`` `…` ``) before scanning a line;
  - collect headings (`#`..`######`) and compute GitHub slugs: lowercase, drop every char
    that is not alnum, space, `-` or `_`, spaces → `-`; repeated slugs get `-1`, `-2`, …;
  - emit inline links `[text](target)` (target up to the first space or `)`; drop an optional
    `"title"`), image links `![alt](…)`, and reference definitions `^ {0,3}\[[^]]+\]: `.
- Classify each link:
  - image → error `image links are not allowed (guides ship no assets)`;
  - reference definition → error `reference-style links are not allowed`;
  - `https://…` → OK (not fetched);
  - any other scheme (`http:`, `file:`, `mailto:`, …) or a path starting with `/` → error
    `link must be relative inside the guides or absolute https://`;
  - `#anchor` → anchor must exist in the same file;
  - relative `path[#anchor]` → normalise against the file's dir (resolve `.`/`..` textually,
    without `realpath -m`), error `relative link leaves the guides tree` if it escapes ROOT,
    `missing file` if it does not exist, `missing anchor` if the anchor is absent from the
    target's slugs (anchors only checked on `*.md` targets).
- Report every problem as `<path relative to ROOT>: <message>: <link>` on stderr; exit 1 if
  any, else `test-docs: OK (<n> file(s))`.
- Must pass shellcheck and run under bash 3.2 (no associative arrays — compute slugs per
  target file on demand, or keep them in a temp dir under `mktemp -d` with a `trap` cleanup).

## Files to Change

- `scripts/check_guides_links.sh` — new.
