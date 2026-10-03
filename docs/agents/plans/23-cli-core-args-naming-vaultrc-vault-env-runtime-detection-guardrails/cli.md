# CLI Plan: CLI core: args, naming, .vaultrc, .vault.env, runtime detection, guardrails

Main plan: [plan.md](plan.md)

## Shared contracts

- **You create**, under `cli/lib/`: `docker.sh`, `args.sh`, `naming.sh`, `config.sh`,
  `guardrails.sh`, `runtime.sh`, `container.sh`. `automation` adds them to `LIBS` in
  `scripts/bundle_cli.sh` in that order, after `output.sh` and `usage.sh`. A library may only
  call functions from libraries earlier in that list, or from `bin/vault`.
- **Open point 1 (settled):** for `vault run`, the first positional argument is `[dir]` only
  when it names an existing directory; `--` ends CLI options.
- **`.vaultrc` I/O:** `config.sh` reads `.vaultrc` lines from stdin; `bin/vault` redirects
  `< "<dir>/.vaultrc"` when the file exists. Only `bin/vault` reads files' existence/content
  for config and environment variables (`PWD`, `DOCKER_HOST`).
- **Deviations** from `docs/agents/specs/cli-*.md` go in the PR description, so
  `product-owner` can write them into the spec in the same PR. Do not edit `docs/agents/`.

## Steps

- [01 — docker wrapper and test harness](cli/01-docker-wrapper-and-test-harness.md)
- [02 — Option parsing](cli/02-option-parsing.md)
- [03 — Instance naming](cli/03-instance-naming.md)
- [04 — .vaultrc, precedence and .vault.env](cli/04-vaultrc-precedence-vault-env.md)
- [05 — Guardrails](cli/05-guardrails.md)
- [06 — Pre-checks and runtime selection](cli/06-prechecks-and-runtime.md)
- [07 — Container arguments and bin/vault wiring](cli/07-container-arguments-and-wiring.md)

## CI Checks
- `cli/`, `test/cli/`: `make lint`, `make test` (current bash and bash 3.2), `make bundle-cli`
  (CI job: `build-and-test`).

## Notes
- **bash 3.2 traps:** `"${arr[@]}"` on an **empty** array fails under `set -u` on bash 3.2
  (`unbound variable`); use `${arr[@]+"${arr[@]}"}` or check `${#arr[@]}` first. No
  associative arrays, `mapfile`, `${var,,}` (use `tr '[:upper:]' '[:lower:]'`), `declare -n`,
  `[[ -v ]]`, nor `read -d ''` tricks that differ across versions.
- Functions cannot return arrays: results go into **module-prefixed globals** (e.g.
  `ARGS_PORTS=()`, `CONFIG_PORTS=()`, `CONTAINER_ARGS=()`), documented in each function's
  header comment. Libraries still only define functions; the globals are set when a function
  runs.
- Errors use `output_error` / `output_warning` / `output_hint` with the spec's exact wording,
  and functions **return** the exit code (1 or 2) rather than calling `exit`, so `bin/vault`
  decides and tests can assert the code.
- Every test that touches docker uses the stub; no test needs a real daemon.
- No command (`up`, `run`, …) is added: those are #24. `vault help` output does not change.
