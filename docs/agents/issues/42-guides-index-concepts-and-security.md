# Issue: Guides: index, concepts and security

## Description
Part of epic #39 (portable user guides for Vault). Fills `docs/guides/vault.md` (#41 created
only its top block and version line) and writes the first two topic pages,
`docs/guides/vault/concepts.md` and `docs/guides/vault/security.md`. Depends on #40 (spec,
merged) and #41 (link check, merged). Agent: `product-owner`.

## Problem
Consumer repos need an entry point that explains what Vault is and which way to use it, plus
the foundations (concepts, security) every other page builds on.

## Expected Behavior
Following `docs/agents/specs/guides-pages.md` and `guides-portability.md`:
- `docs/guides/vault.md`:
  - keeps the existing top block (copy the whole tree, originals URL) and the single
    `**Vault version:**` line unchanged;
  - what Vault is and when to use it / when not to;
  - choosing a path: the image directly (`docker run`) vs. the `vault` CLI, and the image as
    is vs. as a base image;
  - a page index listing the pages that exist after this issue (`vault/concepts.md`,
    `vault/security.md`); later sub-issues add their own rows.
- `docs/guides/vault/concepts.md`: one-line purpose + link back to `../vault.md`;
  Docker-in-Docker (inner `dockerd` started by the entrypoint); `/vault` as the working
  directory; port flow (host → Vault `80` → inner service, per the spec's Ports table);
  bind mounts in the inner compose file referring to the Vault container's filesystem; the
  persistence model (`VOLUME /var/lib/docker`); startup sequence in short.
- `docs/guides/vault/security.md`: one-line purpose + link back to `../vault.md`;
  `--privileged` risks, Sysbox (recommended), root inside the container, never exposing the
  inner Docker socket, not mounting the host's `docker.sock`, secrets, supported and
  unsupported runtimes/platforms and architectures.
- Content is checked by hand against the README (`## Usage` → Ports / Bind mounts /
  Persistence, `## Supported runtimes and platforms`, `## Security`) and `AGENTS.md`. The
  README itself is not changed (that is #47).
- Pages not written yet (`vault/docker-run.md`, `vault/cli.md`, `vault/base-image.md`,
  `vault/configuration.md`, …) are named in inline code, **not linked**, so the link check
  passes. The sub-issue that writes a page turns those mentions into relative links and adds
  its page-index row. This rule is added to the spec (`guides-overview.md`, next to "Each
  page sub-issue also adds its page to the page index") in the same PR.
- All links follow the portability rules; `make test-docs` passes.
