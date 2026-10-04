# Plan: CLI end-to-end test in CI (make test-cli-e2e)

Issue: [27-cli-end-to-end-test-in-ci-make-test-cli-e2e.md](../../issues/27-cli-end-to-end-test-in-ci-make-test-cli-e2e.md)

## Overview
Add `make test-cli-e2e`, backed by `scripts/test_cli_e2e.sh`. It drives the real bundled CLI
(`build/vault up/status/compose/down`) against the freshly built image and the `test/fixture`
stack, then installs the CLI via `install.sh` from that local image into a temp `HOME`. CircleCI's
`build-and-test` job runs it right after `make test-image`. The project docs gain the new target
and test layer.

## Agents involved

- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

- Make target: `test-cli-e2e`, depends on `build-image` (so on `bundle-cli`), runs
  `scripts/test_cli_e2e.sh`. Listed in `.PHONY`.
- Inputs (env, already exported by the Makefile): `IMAGE` (default `darthjee/vault:dev`, required),
  `SMOKE_TIMEOUT` (default `120`, positive integer, the HTTP wait timeout). No new Make variable.
- Instance name: `vault-e2e-$$` passed as `--name e2e-$$` (container `vault-e2e-<pid>`, volume
  `vault-e2e-<pid>-data`).
- Success output: the last line is `test-cli-e2e: OK`. Failures print `test-cli-e2e: FAILED: <reason>` to
  stderr, followed by the instance's `docker logs` when it exists, and exit 1.
- CI: `build-and-test` step `Run CLI end-to-end test` → `make test-cli-e2e`, after
  `Build image and run smoke test`.
