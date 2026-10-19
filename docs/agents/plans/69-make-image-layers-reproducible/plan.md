# Plan: Make image layers reproducible

Issue: [69-make-image-layers-reproducible.md](../../issues/69-make-image-layers-reproducible.md)

## Overview

Every image build uses a fixed `SOURCE_DATE_EPOCH=0` and `rewrite-timestamp=true`, so layer digests depend only on content. A monthly `APK_REFRESH` build arg rebuilds the `apk add bash` layer once a month so security fixes still arrive. A manual `scripts/check_reproducible.sh` builds twice with no cache and compares layer digests. The image-cache specs record the decisions and the changed shared contract.

## Agents involved

- [dev](dev.md): `Dockerfile` build arg
- [scripts](scripts.md): `release.sh` flags, docker stub, `release.bats`, `check_reproducible.sh` and its tests
- [automation](automation.md): `Makefile` `build-image` / `release`, CI toolchain check
- [product-owner](product-owner.md): spec updates

## Shared contracts

- **Epoch:** `SOURCE_DATE_EPOCH=0` (Unix epoch), fixed. Every build entry point sets it in the
  environment of `docker buildx build` (which forwards it to BuildKit), defaulting to `0` and
  allowing an env override (`SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"`). Replaces
  `git log -1 --format=%ct`, so builds no longer need git metadata.
- **Timestamp rewrite:** every image output has `rewrite-timestamp=true`:
  - release: `--output type=image,push=<true|false>,rewrite-timestamp=true` (replaces `--push`;
    tag names still come from `-t`);
  - local / `build-and-test`: `docker buildx build --load` with
    `--output type=docker,rewrite-timestamp=true` (or equivalent; see automation notes).
- **Cache-bust build arg:** `APK_REFRESH`, format `YYYY-MM` (UTC month, `date -u +%Y-%m`).
  - `Dockerfile`: `ARG APK_REFRESH=unset` declared directly after `FROM` and before
    `RUN apk add --no-cache bash`, and referenced in that `RUN`, so a new value invalidates the
    `apk` layer and every later layer.
  - `scripts/release.sh`: `APK_REFRESH="${APK_REFRESH:-$(date -u +%Y-%m)}"`, always passed as
    `--build-arg APK_REFRESH=...`.
  - `Makefile`: `APK_REFRESH ?= $(shell date -u +%Y-%m)`, passed by `build-image` as
    `--build-arg APK_REFRESH=$(APK_REFRESH)`; `release` forwards it to `release.sh` as an env
    var when set on the command line.
- **Minimum tooling:** BuildKit with `rewrite-timestamp` support (v0.13+) and a buildx that
  forwards `SOURCE_DATE_EPOCH`. The exact minimums found are written into the spec.
- **Digest check:** `scripts/check_reproducible.sh` (manual only, not in CI) builds the image
  twice with `--no-cache`, using the same flags and `APK_REFRESH`, and compares
  `docker image inspect --format '{{json .RootFS.Layers}}'`. Exit 0 if identical, 1 otherwise,
  printing the differing layer indexes.
