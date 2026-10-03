# Plan: CLI core: args, naming, .vaultrc, .vault.env, runtime detection, guardrails

Issue: [23-cli-core-args-naming-vaultrc-vault-env-runtime-detection-guardrails.md](../../issues/23-cli-core-args-naming-vaultrc-vault-env-runtime-detection-guardrails.md)

## Overview
Build the CLI core under `cli/lib/`: option parsing, instance naming, the `.vaultrc` parser
and precedence, `.vault.env`, the docker pre-checks, runtime selection and the guardrails. It
ends in one function that builds the complete `docker run` argument list for `up` and `run`,
which #24 then executes. No user-facing command is added. `cli` writes the code and tests,
`automation` registers the new libraries in the bundle order, and `product-owner` records
the settled open point in the spec.

## Agents involved

- [cli](cli.md)
- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

- **New library files and bundle order** (`scripts/bundle_cli.sh` → `LIBS`), exactly:
  `output.sh`, `usage.sh`, `docker.sh`, `args.sh`, `naming.sh`, `config.sh`,
  `guardrails.sh`, `runtime.sh`, `container.sh`. `bundle_cli.sh` fails when a
  `cli/lib/*.sh` file is missing from `LIBS`, so both changes land in the same PR. A library
  only calls functions from libraries earlier in the list, or from `bin/vault`.
- **Open point 1, settled:** for `vault run`, the first positional argument is `[dir]` only
  when it names an existing directory; otherwise it is the first compose argument. `--` ends
  CLI options explicitly.
- **`.vaultrc` I/O:** `config.sh` parses `.vaultrc` lines from **stdin**; `cli/bin/vault`
  feeds it with `< "<dir>/.vaultrc"` (only when the file exists). Only `bin/vault` reads files
  and environment variables (`PWD`, `DOCKER_HOST`); libraries get them as arguments.
- **Spec deviations:** if `cli` deviates from `docs/agents/specs/cli-*.md` (e.g. the exact
  container argument order, which the spec leaves to #23 / #24), it lists them in the PR
  description and `product-owner` writes them into the spec in the same PR.
