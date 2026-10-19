# Automation Plan: Make image layers reproducible

Main plan: [plan.md](plan.md)

## Shared contracts

- `make build-image` builds with `SOURCE_DATE_EPOCH` (default `0`, env override),
  `rewrite-timestamp=true`, and `--build-arg APK_REFRESH=$(APK_REFRESH)`, where
  `APK_REFRESH ?= $(shell date -u +%Y-%m)`. The result is still loaded as `$(IMAGE)`, so
  `scripts/test_image.sh` and `scripts/test_cli_e2e.sh` keep working.
- `make release` forwards `APK_REFRESH` to `scripts/release.sh` when it is set; `release.sh`
  computes the month itself otherwise.
- `release.sh` (owned by `scripts`) implements the release-side flags; `automation` owns the
  design and the CI toolchain.

## Implementation Steps

### Step 1 — Reproducible `build-image`

Change the `build-image` recipe from `docker build` to
`SOURCE_DATE_EPOCH=$${SOURCE_DATE_EPOCH:-0} docker buildx build --load --output type=docker,rewrite-timestamp=true ...`
(or the equivalent form that both the local default `docker` driver and CI accept), keeping the
optional `DOCKER_VERSION` build arg, adding `--build-arg APK_REFRESH=$(APK_REFRESH)`, and tagging
`$(IMAGE)`. Add `APK_REFRESH ?= $(shell date -u +%Y-%m)` next to the other `?=` variables.
Forward it in `release`: `$(if $(APK_REFRESH),APK_REFRESH=$(APK_REFRESH)) scripts/release.sh $(TAG)`.
Then check: run `make build-image` twice and compare `docker image inspect --format '{{json .RootFS.Layers}}' $(IMAGE)`
(or run `scripts/check_reproducible.sh` once `scripts` delivers it).

### Step 2 — Check the CI toolchain

Find the minimum BuildKit/buildx versions for `rewrite-timestamp` and `SOURCE_DATE_EPOCH`
forwarding (BuildKit v0.13+ expected). Confirm that:
- the `ubuntu-2404:current` machine image's Docker/buildx (used by `build-and-test` on the
  default driver) supports the `build-image` command, and
- the `docker-container` builder created by `scripts/ci/setup_buildx.sh` runs a BuildKit that
  has it.

If the builder's BuildKit image is not pinned and should be, pin it in `scripts/ci/setup_buildx.sh`
with `--driver-opt image=moby/buildkit:<version>`, following the pinned `BINFMT_IMAGE` pattern.
Report the minimum versions found to `product-owner` for the spec.

## Files to Change

- `Makefile` — `APK_REFRESH` variable, `build-image` recipe, `release` forwarding.
- `scripts/ci/setup_buildx.sh` — only if a BuildKit image pin is needed.

## CI Checks

- `make lint` (CI job: `build-and-test`)
- `make test-image`, `make test-cli-e2e` (CI job: `build-and-test`)

## Notes

- Risk: the default `docker` driver on the classic (non-containerd) image store may ignore
  `rewrite-timestamp`. If so, pick the option that keeps `--load` working: containerd image
  store, or a local `docker-container` builder plus `--load`. Record the choice in the spec.
- `$$` escapes `$` inside the Makefile recipe.
