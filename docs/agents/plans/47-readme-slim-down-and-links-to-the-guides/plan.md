# Plan: README slim-down and links to the guides

Issue: [47-readme-slim-down-and-links-to-the-guides.md](../../issues/47-readme-slim-down-and-links-to-the-guides.md)

## Overview
Apply [guides-readme.md](../../specs/guides-readme.md). The README shrinks to an overview, a quick
start, a link to the guides and a short Security summary. Its detailed sections are deleted,
because `docs/guides/` already holds them. Every link that pointed at a removed section moves to
the guides. That covers the Docker Hub description, `AGENTS.md`, `docs/agents/` and the CLI
rootless hint. Two leftovers from #46 are fixed too: the out-of-date `product-owner.md` line and
the `my-app` tag clash in `base-image.md`.

## Agents involved

- [cli](cli.md): the rootless hint text and its tests.
- [automation](automation.md): `DOCKERHUB_DESCRIPTION.md` links.
- [product-owner](product-owner.md): `docs/agents/*` and `docs/guides/vault/base-image.md`.
- [architect](architect.md): `README.md`, `AGENTS.md`, `.claude/agents/product-owner.md`. Runs
  last, after checking the others' wording.

The four parts touch disjoint files and can run in parallel. The architect does the final
cross-check.

## Shared contracts

- **Guide URLs (absolute, outside `docs/guides/`):** base
  `https://github.com/darthjee/vault/blob/main/docs/guides/`.
  - Index: `…/docs/guides/vault.md`
  - CLI: `…/docs/guides/vault/cli.md`
  - Security: `…/docs/guides/vault/security.md`
  - Supported runtimes: `…/docs/guides/vault/security.md#supported-runtimes-and-platforms`
- **Relative links from repo files** (`README.md`, `AGENTS.md`, `docs/agents/*`): use relative
  paths to `docs/guides/...` (for example `docs/guides/vault.md` from the root and
  `../guides/vault/security.md` from `docs/agents/`).
- **The README keeps a `## Security` heading** (anchor `#security`), so the CLI warning
  `… (see Security in the README)` stays valid.
- **New rootless hint text** (exact): `see Security in the README`, so stderr reads
  `vault: hint: see Security in the README`. The README Security summary must say that rootless
  Docker is unsupported, and name Sysbox (preferred) and `--privileged` (fallback).
- **Removed README anchors:** `#cli`, `#usage`, `#running`, `#arguments`, `#ports`,
  `#persistence`, `#offline-preload`, `#bind-mounts`, `#environment-variables`, `#behaviour`,
  `#supported-runtimes-and-platforms` (and every CLI subsection). Nothing may link to them
  afterwards.
- The spec under `docs/agents/specs/` stays (#48 removes it).
