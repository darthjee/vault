# CLI Spec: Configuration

Part of the CLI spec for epic #20. Index: [cli-overview.md](cli-overview.md). Implemented in #23.

## Sources

| Source | Where | Role |
|--------|-------|------|
| Flags | command line | Highest precedence. |
| `.vaultrc` | `[dir]`, else `$PWD` | Per-project CLI defaults. Parsed, **never `source`d**. |
| Built-in defaults | the CLI | Lowest precedence. |
| `.vault.env` | `[dir]`, else `$PWD` | Env file for the Vault container. Independent of the precedence chain. |

- Only `cli/bin/vault` reads `.vaultrc` and the environment; libraries receive values as
  arguments. The `.vaultrc` parser (`cli/lib/config.sh`) reads its lines from **stdin**;
  `bin/vault` feeds it with `< "<dir>/.vaultrc"`, only when the file exists. The libraries
  open no file and read no environment variable (`PWD`, `DOCKER_HOST` are passed in).
- The CLI reads no environment variable of its own in this epic. In particular, an exported
  `VAULT_VERSION` does not change the CLI's version or default image (it only affects
  `install.sh`).

## `.vaultrc`

### Format

```
# .vaultrc
name=my-app
image=darthjee/vault:0.2.0
runtime=sysbox
port=3000:80
port=3443:443
volume=/data/shared:/shared
env=RAILS_ENV=production
env-file=.env.prod
```

### Keys

Lowercase, mirroring the long flags.

| Key | Flag | Repeatable | Default | Values |
|-----|------|------------|---------|--------|
| `name` | `--name` | no | see [instance naming](cli-commands.md#instance-naming) | `[a-z0-9][a-z0-9_.-]*` |
| `image` | `--image` | no | `darthjee/vault:<VAULT_VERSION>` | any image reference |
| `runtime` | `--runtime` | no | `auto` | `auto`, `sysbox`, `privileged` |
| `port` | `-p` / `--port` | yes | `3000:80` | a `docker run -p` mapping |
| `volume` | `-v` / `--volume` | yes | none | a `docker run -v` mount |
| `env` | `-e` / `--env` | yes | none | `KEY=VALUE` or `KEY` (as `docker run -e`) |
| `env-file` | `--env-file` | yes | none | a file path |
| `stop-timeout` | `--stop-timeout` | no | `60` | positive integer (seconds) |

- `image=` changes the image only. Unlike `--image`, it does not change the name default nor
  skip the `/vault` mount.
- Relative `volume` sources and `env-file` paths resolve against the directory holding
  `.vaultrc`.
- The guardrails apply to `.vaultrc` entries exactly as to flags
  ([privilege model](cli-commands.md#privilege-model)).

### Parsing rules

- One `key=value` per line. The key is everything before the first `=`; the value is
  everything after it, **verbatim**: no quoting, no escape handling, no variable expansion, no
  trimming of the value.
- Values are never split on whitespace, so paths with spaces work.
- `#` starts a comment only at the beginning of a line. Blank lines are ignored.
- A repeatable key adds one entry per line, in file order. A non-repeatable key given twice:
  the last line wins.
- An unknown key warns and is skipped.
- A non-blank, non-comment line without `=` fails, naming the line number.
- A known key with an invalid value (e.g. `runtime=foo`, `stop-timeout=0`) fails, naming the
  line number. `env` values are not validated and never echoed.
- Lines are numbered from 1. A missing `.vaultrc` is not an error.
- Must work under bash 3.2 (plain indexed arrays only).

## Precedence

**Flags > `.vaultrc` > built-in defaults.**

- Scalar keys (`name`, `image`, `runtime`, `stop-timeout`): the flag wins over `.vaultrc`, which
  wins over the default.
- List keys **replace per key**: any `-p` replaces every `.vaultrc` `port`; the same holds for
  `-v` / `volume`, `-e` / `env` and `--env-file` / `env-file`. A key with no flag keeps its
  `.vaultrc` entries.
- The `3000:80` port default applies only when neither flags nor `.vaultrc` give a port.

## `.vault.env`

- When `<dir>/.vault.env` exists, it is passed as `--env-file` **before** every `env-file` /
  `--env-file`, so explicit files (and `-e`, passed after them) win.
- It is passed to `up` and `run` only, regardless of the precedence chain: a `--env-file` flag
  does not replace it.
- The CLI never reads its content; docker does.

## Errors

The `vault: ` prefix is omitted. Full table: [cli-commands.md → Messages](cli-commands.md#messages).

| Case | Message | Exit |
|------|---------|------|
| Unknown key | `warning: .vaultrc:<line>: unknown key '<key>'` | — (continues) |
| Line without `=` | `error: .vaultrc:<line>: expected key=value` | 1 |
| Invalid value | `error: .vaultrc:<line>: invalid value for <key>: '<value>'` | 1 |
| Guardrail hit by a `.vaultrc` entry | the guardrail message | 2 |
