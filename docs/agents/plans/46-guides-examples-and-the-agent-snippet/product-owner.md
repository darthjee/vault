# Product Owner Plan: Guides: examples and the agent snippet

Main plan: [plan.md](plan.md)

## Overview
Write `docs/guides/vault/examples.md` and `docs/guides/vault/agents-snippet.md` following the
guides spec (`docs/agents/specs/guides-pages.md` → `examples.md`, `agents-snippet.md`, Ports,
Image tags; `guides-portability.md` → Portability rules), then add both pages to the page
index of `docs/guides/vault.md`.

## Context
- Pages #42–#45 have landed: `concepts.md`, `security.md`, `cli.md`, `docker-run.md`,
  `base-image.md`, `configuration.md`, `operations.md`, `troubleshooting.md`. The new pages
  link to them for details instead of repeating them.
- No existing guide page mentions `examples.md` or `agents-snippet.md` in inline code, so
  there are no "not yet written" mentions to turn into links.
- Facts to reuse (keep wording/flags consistent with the existing pages):
  - Port flow: host → Vault `80` → inner service via `ports: ["80:3000"]`
    (`concepts.md#port-flow`). `docker run` variants use `-p 8080:80`; CLI variants use the
    default `3000:80` (no `-p`) unless they pass `-p`.
  - Data volume: `docker run` mounts a named volume on `/var/lib/docker`
    (`docker-run.md#the-data-volume`); the CLI creates `vault-<name>-data` itself
    (`cli.md#instances`), where `<name>` is the basename of `[dir]`.
  - Runtime: Sysbox (`--runtime=sysbox-runc`) recommended, `--privileged` fallback pointing to
    `security.md`; the CLI auto-detects (`cli.md#runtime`).
  - Multiple compose files: `COMPOSE_FILE=compose.yml:compose.prod.yml`, paths relative to
    `/vault` (`configuration.md#multiple-compose-files`); CLI passes it with `-e`.
  - Offline preload: `docker save -o images/<x>.tar <image>` into the project's `images/`;
    Vault `docker load`s `/vault/images/*.tar`; `COMPOSE_UP_ARGS="--pull never"` or
    `pull_policy:` to prevent pulls (`base-image.md#offline-preload`); baked image run with
    `vault up --image my-app` (`cli.md#baked-images`).
  - Secrets: env files out of git, never baked into images (`configuration.md#secrets-handling`).
- Open point #6 of `guides-overview.md` is settled by the issue: `postgres:17`, `redis:7`, and
  a placeholder `my-app` image; Vault tag placeholder `darthjee/vault:<version>`.

## Steps

- [01 — Write examples.md](product-owner/01-write-examples.md)
- [02 — Write agents-snippet.md](product-owner/02-write-agents-snippet.md)
- [03 — Index both pages in vault.md and verify](product-owner/03-index-and-verify.md)

## CI Checks
- `docs/guides/`: `make test-docs` (CI job: `build-and-test`, step `make test-docs`).
- No shell, image or CLI files change, so `make lint` / `make test` are unaffected (run them
  anyway if convenient).

## Notes
- All links: relative between guide pages, absolute `https://` for anything outside
  `docs/guides/`, no links into the consumer repo, no images or reference-style links (the
  link check rejects them). Links inside fenced code blocks are not checked — the snippet's
  paths live inside a fenced block, so they are not validated; double-check them by hand.
- Don't mark the guides spec or the epic as done; #47 (README slim-down) and #48 (remove the
  spec) follow.
- Out of scope but noticed: `.claude/agents/product-owner.md` still says `docs/guides/` "does
  not exist yet; #42 creates it". Flag it to the architect rather than editing agent files here.
