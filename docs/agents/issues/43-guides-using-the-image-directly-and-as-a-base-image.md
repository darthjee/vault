# Issue: Guides: using the image directly and as a base image

## Description
Part of epic #39 (portable user guides for Vault). Depends on #42 (index, concepts, security —
already merged). Can run in parallel with #44 (CLI page) and #45 (configuration, operations,
troubleshooting). Agent: `product-owner`.

Spec: [guides-pages.md → docker-run.md](../specs/guides-pages.md#docker-runmd) and
[→ base-image.md](../specs/guides-pages.md#base-imagemd), plus
[guides-portability.md](../specs/guides-portability.md#portability-rules).

## Problem
Consumer repos need to know how to run their stack with the published image without the CLI,
and how to ship the stack as its own image built on Vault. `vault.md` currently names both
pages as "not written yet".

## Expected Behavior
- `docs/guides/vault/docker-run.md` (using the image directly):
  - one-line purpose and a link back to `../vault.md`;
  - Sysbox (`--runtime=sysbox-runc`, recommended) vs. `--privileged` (fallback, linking to
    `security.md`);
  - mounting the compose project at `/vault`, and the data volume on `/var/lib/docker`;
  - ports (`-p 8080:80`, said on the page), env vars (`-e`, `--env-file`), compose passthrough
    arguments: no arguments → `docker compose up ${COMPOSE_UP_ARGS}`; arguments →
    `docker compose "$@"` (`config`, `ps`, `up --build`);
  - stopping with enough grace time: one short `--stop-timeout` / `docker stop -t` example,
    pointing to `operations.md` for the full shutdown sequence (stop timeouts stay owned by
    #45); add this line to the spec's `docker-run.md` section.
- `docs/guides/vault/base-image.md` (using Vault as a base image):
  - one-line purpose and a link back to `../vault.md`;
  - `FROM darthjee/vault:<version>` + `COPY . /vault`;
  - offline preload (`/vault/images/*.tar`, `docker save`, `COMPOSE_UP_ARGS="--pull never"` /
    `pull_policy:`);
  - running the baked image with `docker run` (`-p 8080:80`) and with `vault up --image`;
  - not baking secrets into the image.
- `vault.md`: the "Choosing a path" tables link both pages instead of "not written yet", and
  the page index gets one row per new page.
- Image tags use `darthjee/vault:<version>`; `latest` only in quick starts, said explicitly.
- Pages not written yet (`cli.md`, `configuration.md`, `operations.md`) are named in inline
  code, not linked; whichever of #44 / #45 lands later turns those mentions into links.
- All links follow the portability rules; `make test-docs` passes.
