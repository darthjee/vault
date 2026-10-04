# Plan: Guides spec (docs/agents/specs/guides-*.md) and docs/guides ownership

Issue: [40-guides-spec-docs-agents-specs-guides-md-and-docs-guides-ownership.md](../../issues/40-guides-spec-docs-agents-specs-guides-md-and-docs-guides-ownership.md)

## Overview

First sub-issue of epic #39. `product-owner` turns the guides design from the body of #39 into
a spec under `docs/agents/specs/guides-*.md`, registers it in the spec hub
(`docs/agents/specs.md`) and lists `docs/guides/` in `folder-structure.md`. `architect`
extends `product-owner`'s scope to `docs/guides/` in the agent definitions and the agent
tables. Documentation only: no guide pages, scripts, Makefile or CI changes.

## Agents involved

- [product-owner](product-owner.md)
- [architect](architect.md)

`architect` is the coordinator, but it is listed here because the agent files and `AGENTS.md`
are in its own scope (`.claude/`, root-level files), as #39's "Responsible agents" says.

## Shared contracts

- **Spec files** (all under `docs/agents/specs/`, prefix `guides-`):
  - `guides-overview.md` — index of the spec (the hub row links here);
  - `guides-pages.md` — page list, per-page content, audience/style, ports;
  - `guides-portability.md` — portability rules, version line, link check contract;
  - `guides-readme.md` — README split.
- **Hub row** in `docs/agents/specs.md` → **Active specs** (replaces the `None` row):

  ```markdown
  | [`guides-`](specs/guides-overview.md) | #39 | #48 |
  ```

- **Ownership wording** (same everywhere: `product-owner.md`, `AGENTS.md` table, `architect.md`
  table, `folder-structure.md`, `guides-overview.md` → Agent ownership):
  `product-owner` owns `docs/agents/` (incl. `specs/`) **and `docs/guides/`** (portable user
  guides, copied by hand into consumer repos). `docs/guides/` does not exist yet; #42 creates it.
- No `AGENTS.md` override note: the existing `Specs` row already points to the hub, which
  defines precedence, deviations and removal.
