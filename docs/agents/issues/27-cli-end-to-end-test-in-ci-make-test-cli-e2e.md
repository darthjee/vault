# Issue: CLI end-to-end test in CI (make test-cli-e2e)

## Description
Part of epic #20 (Vault CLI). Depends on the CLI commands (#24) and install-path (#26) sub-issues, both done. Owner agent: `automation`. Follow `docs/agents/specs/*.md` (mainly [cli-ci.md](../specs/cli-ci.md#pr-pipeline) and [cli-tooling.md](../specs/cli-tooling.md#testing-strategy)).

## Problem
The CLI unit tests stub `docker`, and `make test-image` only exercises the image directly (`docker run`, `vault-install`). Nothing checks that the real bundled CLI (`build/vault`), the real image and `install.sh` work together.

## Expected Behavior
- A `make test-cli-e2e` target, with its logic in `scripts/test_cli_e2e.sh`. It:
  - builds the image and the bundle (the target depends on `build-image`, which already runs `bundle-cli`);
  - picks a free localhost port at runtime and runs `build/vault up` against `test/fixture` with `--name` set to a unique per-run name (e.g. `vault-e2e-$`), `--image $IMAGE` (the freshly built tag), `--runtime=privileged` forced (no Sysbox in CI) and `-p <free port>:80`;
  - `curl`s the published port until it answers HTTP 200, within `SMOKE_TIMEOUT`;
  - runs `status` and `compose ps` (both exit 0);
  - runs `down` and checks a clean shutdown: `down` exits 0, prints `vault-<name> stopped and removed (volume vault-<name>-data kept)`, the container no longer exists, and the volume `vault-<name>-data` still exists. The image's own exit code on stop is already covered by `make test-image`;
  - runs `install.sh` with `VAULT_IMAGE=$IMAGE`, and with `HOME` and `VAULT_INSTALL_DIR` pointing into a temp dir so the real home is never touched. It checks that:
    - `install.sh` exits 0 and prints `installed vault <VERSION> to …`;
    - the installed `vault version` prints `vault $(cat VERSION)`;
    - the installed file is owned by the current user;
    - both `completion/vault.bash` and `completion/_vault` land under the temp `HOME/.local/share/vault/completion/`.
  - always cleans up what it created, success or failure: the container, the `vault-<name>-data` volume and the temp dirs. On failure it dumps `docker logs` of the instance.
- The CircleCI `build-and-test` job runs `make test-cli-e2e` after `make test-image`, on the machine executor. No new job, no new context.
- The PR pipeline passes.

## Solution
- `Makefile`: add `test-cli-e2e: build-image` calling `scripts/test_cli_e2e.sh`; add it to `.PHONY`.
- `scripts/test_cli_e2e.sh`: modelled on `scripts/test_image.sh` (`validate_inputs`, `fail` that dumps logs, `trap _cleanup EXIT`), reusing `IMAGE` and `SMOKE_TIMEOUT`.
- `.circleci/config.yml`: a new step in `build-and-test` after the smoke test.

## Benefits
Catches integration breaks that stubbed unit tests cannot see, between the CLI's generated `docker` arguments, the image's entrypoint and the install path, before a release.
