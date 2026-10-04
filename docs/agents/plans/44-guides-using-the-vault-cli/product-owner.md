# Product Owner Plan: Guides: using the vault CLI

Main plan: [plan.md](plan.md)

## Overview
Add `docs/guides/vault/cli.md` following
[guides-pages.md → cli.md](../../specs/guides-pages.md#climd) and the
[portability rules](../../specs/guides-portability.md#portability-rules). Wire it into
`vault.md`, `docker-run.md` and `base-image.md`.

## Context
- Source of truth for content: README `## CLI` (Install, Installer variables, Completion and
  PATH, Download and verify, Commands, Instances, Runtime, Options and configuration,
  `.vault.env`, `.vaultrc`, Guardrails, Baked images, Docker Desktop), mapped to `vault/cli.md`
  by [guides-readme.md](../../specs/guides-readme.md). Check every flag, default and message
  against `cli/bin/vault`, `cli/lib/*.sh`, `cli/completion/*` and `install.sh`. Where the README
  and the code disagree, the code wins; note the mismatch in the PR.
- Already written: `vault.md`, `concepts.md`, `security.md` (#42), `docker-run.md`,
  `base-image.md` (#43). Pages still pending (`configuration.md`, `operations.md`,
  `troubleshooting.md`, `examples.md`) are named in inline code with "(not written yet)", not
  linked.
- The guides must work once copied into another repo: relative links stay inside
  `docs/guides/`, links to this repo are absolute `https://github.com/darthjee/vault/...` URLs.

## Steps

- [01 — Install, platforms and completion](product-owner/01-install-platforms-completion.md)
- [02 — Commands, instances and runtime](product-owner/02-commands-instances-runtime.md)
- [03 — Options, configuration, guardrails and baked images](product-owner/03-options-configuration.md)
- [04 — Cross-links from existing pages](product-owner/04-cross-links.md)

## CI Checks
- `docs/guides/`: `make test-docs` (CI job running `make test-docs` in `.circleci/config.yml`)

## Notes
- Out of scope: repointing README, `DOCKERHUB_DESCRIPTION.md` and `AGENTS.md` links to the
  guides (owned by a later sub-issue of epic #39, per `guides-readme.md`), and the CLI code
  itself.
- `.vaultrc` must have its own heading so the `cli.md#vaultrc` anchor (the portability spec's
  example) resolves.
- Detailed secrets handling and stop-timeout semantics belong to `configuration.md` /
  `operations.md` (#45); `cli.md` only points to them in inline code.
- Keep the version line in `vault.md` unchanged (no release in this issue).
