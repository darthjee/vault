# Automation Plan: Install path: image ships the CLI, install entry, install.sh

Main plan: [plan.md](plan.md)

## Shared contracts

- **Produces** the build prerequisite: `build/vault` exists before every image build.
- **Relies on** `dev`'s in-image paths and `vault-install` contract for the image check, and on
  `cli`'s `install.sh` version line for the version scripts.

## Steps

- [01 — Run bundle-cli before every image build](automation/01-bundle-before-build.md)
- [02 — Make install.sh required in the version scripts](automation/02-version-scripts.md)
- [03 — Image check: the CLI and the install entry](automation/03-image-check.md)

## CI Checks
- `Makefile`, `scripts/`: `make lint`, `make test`, `make test-image` (CI job: `build-and-test`)
- Release path: `make check-version-tag TAG=0.0.1`, and `make release TAG=x PUSH=false` when a buildx builder is available.

## Notes
- The CI `build-and-test` job already runs `make bundle-cli` before `make test-image`; the Make
  dependency makes it redundant but harmless. Leave `.circleci/config.yml` as is. Check that the
  release job (`make release`) can run `bundle-cli` (it only needs bash and coreutils).
- Step 02 needs `cli`'s `install.sh`. Until it lands, `check-version-tag` fails, which is
  expected inside this PR's sequencing.
