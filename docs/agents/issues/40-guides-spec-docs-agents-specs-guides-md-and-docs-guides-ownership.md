# Issue: Guides spec (docs/agents/specs/guides-*.md) and docs/guides ownership

## Description
Part of epic #39 (portable user guides for Vault), and its **first** sub-issue. It depends on epic
#20 (Vault CLI): all of #20's sub-issues (#21–#30) are closed, #30 has added the spec hub
`docs/agents/specs.md`, and `docs/agents/specs/` is empty again.

Agents:
- `product-owner` writes the spec, registers it in the spec hub and updates `folder-structure.md`;
- `architect` extends the `product-owner` agent (and the `AGENTS.md` agents table) to own
  `docs/guides/`.

Documentation and agent definitions only: no guide pages, scripts, Makefile or CI.

## Problem
The guides design lives only in the body of epic #39. The later sub-issues (#41–#48) need one
agreed reference for the page list, the portability rules, the version line and who owns
`docs/guides/`. No agent owns `docs/guides/` today (`product-owner` owns `docs/agents/` only).

## Expected Behavior
- `docs/agents/specs/guides-*.md` exist, following the naming rules of `docs/agents/specs.md`,
  with a `guides-overview.md` index. Together they fix:
  - **Page list and content:** `docs/guides/vault.md` (index: what Vault is, when to use it,
    choosing a path, page index) and `docs/guides/vault/` pages `concepts.md`,
    `docker-run.md`, `cli.md`, `base-image.md`, `configuration.md`, `operations.md`,
    `troubleshooting.md`, `security.md`, `examples.md`, `agents-snippet.md`, with the
    topics each one covers (as listed in #39).
  - **Audience and style:** humans and AI agents in consumer repos; plain, task-oriented
    Markdown.
  - **Portability rules:** relative links only between guide pages, each resolving inside
    `docs/guides/` (anchors included); absolute `https://` URLs for anything outside
    `docs/guides/`; no links into the consumer repo's own files; no assets; the copy unit is
    the whole `docs/guides/` tree; `vault.md` states where the originals live.
  - **Version line:** the exact format of the `**Vault version:** X.Y.Z` line in `vault.md`,
    and that examples use `darthjee/vault:<version>` (or `:latest` in quick starts, said
    explicitly).
  - **Link check contract:** what the check enforces, the Make target name (e.g.
    `make test-docs`), and where it runs in CI.
  - **README split:** which README sections move to the guides and what the README keeps.
  - **Ports:** the CLI default `3000:80` vs. the `docker run` examples' `-p 8080:80`, and how
    the guides present them.
  - A **sub-issue map** (#41–#48 → spec sections) and open points.
- `docs/agents/specs.md` is the hub that points to the spec files: in its **Active specs**
  table, the `None` row is replaced by a `guides` row (epic #39, removed by #48) whose prefix
  links to `specs/guides-overview.md`. `AGENTS.md` gets no extra note: its existing `Specs`
  row already points to the hub. Precedence, deviations and removal are not restated anywhere: the hub
  already defines them (the spec overrides the agent docs and the epic body while #39 is open,
  a deviating PR updates the spec in the same PR, #48 deletes it and its row).
- `docs/agents/folder-structure.md` lists `docs/guides/` (portable user guides, copied by hand
  into consumer repos; owned by `product-owner`).
- `.claude/agents/product-owner.md` (scope list and `description`) and the `AGENTS.md` agents
  table list `docs/guides/` in `product-owner`'s scope.
- No tests (documentation only).
