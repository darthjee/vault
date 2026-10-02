# Plan: Docker image smoke test (make test-image)

Issue: [7-docker-image-smoke-test-make-test-image.md](../../issues/7-docker-image-smoke-test-make-test-image.md)

## Overview

Replace the `test-image` no-op stub with an end-to-end smoke test of the built image. `dev` adds a one-service compose fixture under `test/fixture/`. `automation` adds `scripts/test_image.sh` and wires it into `make test-image` (with `build-image` as a prerequisite). The script runs Vault `--privileged` with the fixture on a random localhost port, curls it, asserts no listener on 2375, stops it cleanly and always cleans up. `product-owner` records the new `SMOKE_TIMEOUT` variable in the spec.

## Agents involved

- [dev](dev.md)
- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

- **Fixture path:** `test/fixture/docker-compose.yml` (repo-relative). The script mounts the directory `test/fixture` read-only at `/vault`. The fixture directory contains no `images/` folder.
- **Fixture service:** exactly one service, image `nginx:1.29-alpine` (pinned by tag), `ports: ["80:80"]`. `GET /` returns HTTP 200 (stock nginx welcome page). No build context, no volumes.
- **Script:** `scripts/test_image.sh`, called only via `make test-image`. Inputs from the environment:
  - `IMAGE` (required; Makefile default `darthjee/vault:dev`)
  - `SMOKE_TIMEOUT` (seconds, positive integer; Makefile default `120`)
- **Make target:** `test-image: build-image`; recipe is a single line running `scripts/test_image.sh`. `SMOKE_TIMEOUT ?= 120` is declared and exported next to the other variables.
- **Exit code:** 0 only when every check passed; non-zero otherwise. Cleanup runs in both cases.
