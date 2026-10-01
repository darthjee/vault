# Plan: Repo scaffolding: VERSION, version scripts, Makefile, lint/test via Docker

Issue: [4-repo-scaffolding-version-version-scripts-makefile-lint-test-via-docker.md](../../issues/4-repo-scaffolding-version-version-scripts-makefile-lint-test-via-docker.md)

## Overview
Scaffold the repo tooling: a `VERSION` file plus a matching README line, two version scripts, host-side lint and test scripts that run shellcheck and bats in pinned Docker images, and a `Makefile` as the only entry point. Image, smoke-test, description and release targets start as no-op stubs. The docker-image spec is updated in the same PR to record the new targets and behaviours.

## Agents involved

- [automation](automation.md): `VERSION`, `scripts/`, `Makefile`.
- [product-owner](product-owner.md): spec updates under `docs/agents/specs/docker-image/`.

The architect adds the `**Current Version:** 0.1.0` line to the root `README.md`, which is a root-level file.

## Shared contracts

- Make targets: `lint`, `test`, `bump-version VERSION=X.Y.Z`, `check-version-tag TAG=X.Y.Z`, `build-image` (stub, #5), `test-image` (stub, #7), `update-description` (stub, #9), `release TAG=x` (stub, #9).
  - `bump-version`, `check-version-tag` and `release` exit non-zero when their variable is missing.
  - The stubs print a notice naming their sub-issue and exit 0.
- Variables: `SHELLCHECK_IMAGE ?= koalaman/shellcheck:v0.11.0`, `BATS_IMAGE ?= bats/bats:1.14.0`.
- README line format: `**Current Version:** X.Y.Z`, which must match `VERSION`.
- Lint covers `*.sh` and `*.bats` files under whichever of `source/`, `scripts/` and `test/` exist. Files are collected on the host because the shellcheck image has no shell. The repo is mounted read-only at `/mnt`.
- Test runs bats over `test/lib` with the repo mounted read-only at `/code`. When `test/lib/` is missing or has no `.bats` files, it prints "no tests found" and exits 0.
- Bats helpers (bats-support, bats-assert, bats-file) ship in `bats/bats:1.14.0` under `/usr/lib/bats` (`BATS_LIB_PATH`). Load them with `bats_load_library <name>`. Nothing is vendored.
