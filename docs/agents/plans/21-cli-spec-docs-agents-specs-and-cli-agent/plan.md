# Plan: CLI spec (docs/agents/specs) and cli agent

Issue: [21-cli-spec-docs-agents-specs-and-cli-agent.md](../../issues/21-cli-spec-docs-agents-specs-and-cli-agent.md)

## Overview
First sub-issue of epic #20 (Vault CLI). Documentation and agent definitions only: `product-owner`
writes the six-file CLI spec under `docs/agents/specs/`, and `architect` creates the `cli` agent,
adjusts the `dev`, `automation` and `architect` agent scopes, and updates `AGENTS.md`. No code,
Makefile, CI or Dockerfile change.

## Agents involved

- [product-owner](product-owner.md)
- [architect](architect.md)

## Shared contracts

- **Spec location:** `docs/agents/specs/`, six flat files: `cli-overview.md`, `cli-commands.md`,
  `cli-config.md`, `cli-install.md`, `cli-tooling.md`, `cli-ci.md`.
- **Override note** (verbatim, in `AGENTS.md`): "During epic #20, `docs/agents/specs/*.md`
  overrides these docs where they conflict."
- **Ownership of new paths** (must be identical in `cli-overview.md` → agent ownership, in the
  agent files and in the `AGENTS.md` agents table):
  - `cli`: `cli/bin/vault`, `cli/lib/*.sh`, `cli/completion/*`, root `install.sh`, `test/cli/`,
    `test/install/`;
  - `dev`: `Dockerfile`, `source/` (including `source/bin/install.sh`, the in-image install
    entry), `test/lib/`, `test/fixture/` and the image tests;
  - `automation`: `.circleci/`, `Makefile`, `scripts/` (incl. `scripts/bundle_cli.sh`,
    `scripts/test_cli_e2e.sh`, `scripts/github_release.sh`), `VERSION`,
    `DOCKERHUB_DESCRIPTION.md`, `test/bash32/`, `build/` (git-ignored bundle output);
  - `product-owner`: `docs/agents/` (including `docs/agents/specs/`);
  - `architect`: root-level files except `install.sh`, `.github/`, `.claude/`.
- **Bundling rule:** `cli/bin/vault` sources libraries through one `# BEGIN LIBS` … `# END LIBS`
  block; `scripts/bundle_cli.sh` replaces it with `cli/lib/*.sh` concatenated in a fixed order
  and writes `build/vault`. Documented in `cli-tooling.md`; the `cli` agent file references it.
- **`cli` agent commands:** `make lint`, `make test`, `make bundle-cli`, `make test-cli-e2e`.
