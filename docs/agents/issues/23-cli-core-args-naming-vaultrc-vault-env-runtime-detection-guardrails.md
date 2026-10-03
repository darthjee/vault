# Issue: CLI core: args, naming, .vaultrc, .vault.env, runtime detection, guardrails

## Description
Part of epic #20 (Vault CLI). It depends on #22 (scaffolding, merged). Agent: `cli`. Follow
`docs/agents/specs/*.md`: [cli-commands.md](../specs/cli-commands.md) (syntax, options,
instance naming, runtime selection, privilege model, messages) and
[cli-config.md](../specs/cli-config.md) (`.vaultrc`, `.vault.env`, precedence). Where this issue
and the spec disagree, the spec wins; a deviation updates the spec in the same PR.

## Problem
`cli/bin/vault` only knows `version` and `help`. Before any command (#24) can run a container,
the CLI needs:
- option parsing;
- instance naming;
- the config sources (`.vaultrc`, `.vault.env`, flags) and their precedence;
- runtime selection, with its safety rules;
- the guardrails.

## Expected Behavior
- **Option parsing** (bash 3.2: plain indexed arrays only, no associative arrays, `mapfile`,
  `${var,,}`, `declare -n` or `[[ -v ]]`):
  - the options of [cli-commands.md → Options](../specs/cli-commands.md#options): `--name`,
    `--image`, `--runtime auto|sysbox|privileged`, `-p`/`--port`, `-v`/`--volume`, `-e`/`--env`,
    `--env-file`, `--stop-timeout`, `-f` (`--attach` for `up`, `--follow` for `logs`);
  - long options as `--opt value` or `--opt=value`, short options as `-x value`;
  - for `up`/`down`/`logs`/`status`, options and `[dir]` in any order; for `compose`/`run`,
    parsing stops at the first non-option argument (after the optional `[dir]` for `run`), and
    `--` ends parsing explicitly;
  - **open point 1** (settled here): for `run`, the first positional is `[dir]` only when it
    names an existing directory;
  - errors (exit 2): unknown option, missing option value, bad option value (`--runtime`,
    `--stop-timeout` not a positive integer, an invalid explicit `--name`).
- **Instance naming:**
  - `--name`, else `name=` in `.vaultrc`; explicit names are validated against
    `[a-z0-9][a-z0-9_.-]*`, never altered;
  - else, with `--image` and no `[dir]`: the image name without registry, path and tag/digest;
  - else, the basename of `[dir]` (else `$PWD`);
  - derived names are lowercased, then stripped of every character outside `[a-z0-9_.-]`; an
    empty result fails with the "bad name" message and the `--name` hint (exit 2);
  - the container is `vault-<name>` and the volume `vault-<name>-data`.
- **`.vaultrc`** (read from `[dir]`, else `$PWD`; a missing file is not an error):
  - `key=value` lines, **parsed, never `source`d**; the value is verbatim after the first `=`;
  - `#` comments only at the start of a line; blank lines ignored;
  - repeatable keys (`port`, `volume`, `env`, `env-file`) add one entry per line; a scalar key
    given twice: the last line wins;
  - unknown key → warning, skipped; a line without `=` → error naming the line (exit 1); a
    known key with an invalid value → error naming the line (exit 1); `env` values are never
    validated nor echoed;
  - relative `volume` sources and `env-file` paths resolve against the `.vaultrc` directory;
  - `image=` changes the image only (not the name default, not the `/vault` mount).
- **Precedence:** flags > `.vaultrc` > built-in defaults (port `3000:80`, image
  `darthjee/vault:<VAULT_VERSION>`, runtime `auto`, stop timeout `60`). List keys replace per
  key: any `-p` replaces every `.vaultrc` `port`, and the same for `-v`, `-e`, `--env-file`.
- **`.vault.env`:** when `<dir>/.vault.env` exists, it is passed as `--env-file` before every
  `env-file` / `--env-file`; a `--env-file` flag does not replace it; its content is never read.
- **Pre-checks and runtime selection** (in the spec's order):
  - `docker` on `PATH` (every command except `help` and `version`) → else `docker not found in
    PATH`, exit 1;
  - `up`/`run` only: **one** `docker info` call reads the runtimes and the security options; a
    failing call → `cannot reach the Docker daemon` + hint, exit 1;
  - `rootless` in the security options → error + hint, exit 1, whatever `--runtime` is;
  - the runtime table of [cli-commands.md → Runtime selection](../specs/cli-commands.md#runtime-selection):
    `auto` picks `sysbox-runc` when listed, else `--privileged` with the fallback warning
    (shown **only** in that case); a forced `sysbox` without Sysbox fails (exit 1, no fallback);
    `privileged` never warns.
- **Guardrails** (exit 2, applied to flags and `.vaultrc` entries alike):
  - a `-v` whose source's last path component is `docker.sock`, or is the path of a `unix://`
    `DOCKER_HOST`;
  - a `-p` whose container side is 2375 or 2376, in every form (`HOST:CONTAINER`,
    `IP:HOST:CONTAINER`, `CONTAINER`, `/tcp`, `/udp`, ranges including them).
- **Container arguments:** a function builds the full `docker run` argument list of
  [cli-commands.md → Container arguments](../specs/cli-commands.md#container-arguments) for
  `up`/`run`, so #24 only executes it. Edge case 14 (CLI version ≠ image version): no check.
- **Messages** use the exact wording of [cli-commands.md → Messages](../specs/cli-commands.md#messages),
  through `output_error` / `output_warning` / `output_hint`.
- **Bats tests** under `test/cli/`: a stub `docker` first on `PATH` records its arguments and
  returns scripted output; every rule above is covered, under bash 3.2 and a current bash. The
  spec's edge cases 1, 3, 9, 11, 12 and 14 are covered here.

## Solution
- **New libraries** under `cli/lib/` (functions only, prefixed by module; names are the `cli`
  agent's choice), e.g. `args.sh`, `naming.sh`, `config.sh`, `runtime.sh`, `guardrails.sh`,
  `docker.sh` (the stubbable `docker` wrapper). `scripts/bundle_cli.sh` concatenates them in a
  fixed order inside the `# BEGIN LIBS` … `# END LIBS` block.
- **`cli/bin/vault`** stays the only reader of the environment and of `.vaultrc`; libraries get
  values as arguments. The `.vaultrc` parser in `config.sh` reads lines from **stdin**, and
  `bin/vault` feeds it with `< "<dir>/.vaultrc"`, so the library does no file IO and is
  unit-tested with here-docs.
- **Boundary with #24:** #23 delivers the whole resolution chain, ending in a function that runs
  the pre-checks and guardrails and builds the complete `docker run` argument list for `up` and
  `run`. #24 executes that list and adds the container lifecycle (running / stopped / missing),
  the commands and their messages. Tests assert the built list.
- **Out of scope:** running any container and the commands themselves (`up`, `down`, `logs`,
  `status`, `compose`, `run`), covered by #24; completion (#25); the README (#29).
- **Spec updates in the same PR:** mark open point 1 as settled (the first positional of `run` is
  `[dir]` only when it names an existing directory; `--` ends CLI options), and record any
  deviation.
