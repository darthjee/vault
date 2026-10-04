# Automation Plan: CLI end-to-end test in CI (make test-cli-e2e)

Main plan: [plan.md](plan.md)

## Shared contracts

- You produce the `test-cli-e2e` Make target, `scripts/test_cli_e2e.sh` and the CircleCI step,
  exactly as named in [plan.md](plan.md#shared-contracts) (target name, `IMAGE`/`SMOKE_TIMEOUT`
  inputs, `test-cli-e2e: OK` / `test-cli-e2e: FAILED: <reason>` output, step name).
- `product-owner` documents them in `docs/agents/` and `AGENTS.md` and relies on those names.

## Steps

- [01 — Add the test-cli-e2e Make target](automation/01-make-target.md)
- [02 — Write scripts/test_cli_e2e.sh](automation/02-e2e-script.md)
- [03 — Run it in CircleCI build-and-test](automation/03-circleci-step.md)

## CI Checks
- `scripts/`, `Makefile`: `make lint` (CI job: `build-and-test`)
- end to end: `make test-cli-e2e` (CI job: `build-and-test`); it needs a real Docker daemon that can
  run `--privileged` containers.

## Notes
- `-p` values are passed through to `docker run` unvalidated (`cli/lib/args.sh`), so
  `-p 127.0.0.1:<port>:80` is accepted. Binding to localhost avoids exposing the port.
- Free port: `python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])'`
  (python3 exists on the `ubuntu-2404` machine image and on macOS). There is a small race between
  picking and binding the port; this is acceptable for CI.
- `compose ps` runs with no TTY in CI; `vault compose` adds `-i`/`-t` only when stdin/stdout are TTYs,
  so no special handling is needed. Run CLI calls with `</dev/null` to keep this deterministic
  locally too.
- `make test-image` already builds `$IMAGE`; the `build-image` dependency rebuilds from cache.
