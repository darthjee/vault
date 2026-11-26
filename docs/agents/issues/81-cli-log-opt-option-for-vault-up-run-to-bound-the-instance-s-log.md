# Issue: CLI: --log-opt option for vault up / run to bound the instance's log

## Problem

`vault up` starts the instance with `docker run`. Everything the outer container writes — its own output, the inner `dockerd`, and `docker compose up` with every service's logs — lands in the container's `json-file` log, which Docker keeps unbounded unless `max-size` / `max-file` are set. The CLI has no way to bound it: `up` accepts only `-p`, `-v`, `-e`, `--env-file`, `--runtime`, `--stop-timeout` and `-f`, and nothing in `.vaultrc` reaches `docker run`'s log options.

The only workaround today is a global `daemon.json` on the host, which changes log behaviour for every container on the machine, not just the Vault instance. A long-running instance therefore grows its log until the host disk fills.

`container_build_args` is the single place that assembles the argument list, and its documented order has no log slot: [cli/lib/container.sh](https://github.com/darthjee/vault/blob/main/cli/lib/container.sh).

## Current behaviour (reference)

| Location | Behaviour today |

|----------|-----------------|

| [cli/lib/args.sh](https://github.com/darthjee/vault/blob/main/cli/lib/args.sh) — `_args_key` | `--log-opt` is not a known option for any command. `_args_key` prints nothing, so `args_parse` prints `vault: error: unknown option '--log-opt'` and exits 2. The value options of `up` and `run` are enumerated in `_args_canonical` (`--runtime`, `-p`/`--port`, `-v`/`--volume`, `-e`/`--env`, `--env-file`); log options are absent. |

| `cli/lib/args.sh` — `_args_reset`, `_args_store` | Repeatable options live in indexed arrays with a `*_SET` marker (`ARGS_PORTS`, `ARGS_VOLUMES`, `ARGS_ENVS`, `ARGS_ENV_FILES`). `-e` is never validated; `-p`, `-v` and `--env-file` reject an empty value with `invalid value for <opt>: ''`. There is no array for log options. |

| [cli/lib/config.sh](https://github.com/darthjee/vault/blob/main/cli/lib/config.sh) — `config_reset`, `_config_set` | The `.vaultrc` keys accepted are `name`, `image`, `runtime`, `stop-timeout`, `port`, `volume`, `env`, `env-file`. A `log-opt=` line falls into the unknown-key branch: `vault: warning: .vaultrc:<line>: unknown key 'log-opt'`, and is skipped. |

| `cli/lib/config.sh` — `config_merge` | Scalars resolve as flag > `.vaultrc` > default. List keys are wholesale: when the flag marker is set, the `ARGS_*` array replaces every `.vaultrc` entry of that key. No list key dedupes or reorders entries. |

| `cli/lib/container.sh` — `container_build_args` | Builds `CONTAINER_ARGS` in a fixed order: `run`; `<runtime> --stop-timeout <n>`; `-v <dir>:/vault`; `-v vault-<name>-data:/var/lib/docker`; extra `-v`; `-p`; `--env-file`; `-e`; then `--name vault-<name> [-d]` (`up`) or `[-i] [-t] --rm` (`run`); the image; for `run`, the compose arguments. No `--log-opt` is ever emitted. |

| [cli/lib/instance.sh](https://github.com/darthjee/vault/blob/main/cli/lib/instance.sh) — `_instance_status_format` | Emits five positional lines — image, image id, `<runtime> <privileged>`, ports, env keys — read back by `_instance_line "$out" 1..5` inside `instance_status_print`. `.HostConfig.LogConfig` is not read and there is no `logs:` line in the status block. |

| [cli/lib/usage.sh](https://github.com/darthjee/vault/blob/main/cli/lib/usage.sh) — `usage_print` | The Options block lists `-e` and `--env-file`, with no log option. |

| [cli/completion/vault.bash](https://github.com/darthjee/vault/blob/main/cli/completion/vault.bash) — `_vault_complete_options`, `_vault_complete_takes_value` | `--log-opt` is listed in neither function, so it is not completed and its value is not expected. |

| [cli/completion/_vault](https://github.com/darthjee/vault/blob/main/cli/completion/_vault) — `runtime_opts` | The shared `up`/`run` option group has no `--log-opt` spec. |

## Expected Behavior

- `vault up --log-opt max-size=10m` produces a `docker run` line containing `--log-opt max-size=10m` after `-e` and before `--name`.

- `vault run --log-opt max-size=10m config` does the same, before `-i`/`-t`/`--rm`.

- With no log option given anywhere, the produced `docker run` line is identical to today's.

- Distinct keys are all emitted, in the order given.

- `--log-opt max-size=1m --log-opt max-size=10m` emits exactly one entry, `max-size=10m`.

- `--log-opt max-size=10m` with `log-opt=max-file=5` in `.vaultrc` emits exactly one entry: the flag's.

- `log-opt` repeated in `.vaultrc` emits every entry, in file order.

- `vault down --log-opt max-size=10m` exits 2 with `vault: error: unknown option '--log-opt'`; same for `logs`, `status` and `compose`.

- `vault up --log-opt ""` exits 2 with `vault: error: invalid value for --log-opt: ''`.

- `vault up --log-opt max-size` and `vault up --log-opt =10m` exit 2 with `vault: error: invalid value for --log-opt: '<value>'`; `log-opt=max-size` in `.vaultrc` exits 1.

- `vault status` prints `logs:     json-file max-file=5, max-size=10m` when both options were set, and `logs:     json-file` when none was, as the last line of the block, after `env:`.

- `vault up --log-opt max-size=10m` on a running instance started with `max-size=1m` prints the status block (exit 0) and `vault: warning: log options differ from the running instance (json-file max-size=1m); run 'vault down' then 'vault up' to apply them` on stderr.

- The same with `log-opt=max-size=10m` in `.vaultrc` instead of the flag prints the same warning.

- `vault up` on a running instance whose options match the requested ones (in any order), whose options are a superset of them (daemon defaults), or with no log option requested, prints no warning; stderr is empty.

- `vault status` with a running option `splunk-token=abc` prints `splunk-token=***` on the `logs:` line; the stale-options warning masks it the same way.

- `vault status` on a missing instance still prints only `name:` and `state:    not found`.

- `vault help` lists the option.

- Both completions offer `--log-opt` on `up` and `run`.

- `make lint`, `make test`, `make test-docs` and `make test-cli-e2e` pass.

## Solution

```bash
vault up  [--log-opt <KEY=VALUE>]... [options] [dir]
vault run [--log-opt <KEY=VALUE>]... [options] [dir] [args...]
```

```
# .vaultrc
log-opt=max-size=10m
log-opt=max-file=5
```

### Semantics

1. `--log-opt <KEY=VALUE>` is repeatable and accepted by `up` and `run` only — the same scope as `-p`, `-v`, `-e` and `--env-file`. Every other command rejects it as an unknown option (exit 2).

2. Both spellings work: `--log-opt max-size=10m` and `--log-opt=max-size=10m`.

3. No built-in default. When no source provides a log option, `container_build_args` emits nothing and Docker's own default (`json-file`, unbounded) applies, so existing users see no change in behaviour.

4. Each surviving entry becomes one `--log-opt <KEY=VALUE>` on the `docker run` line, positioned after the `-e` entries and before `--name` (`up`) or `-i`/`-t`/`--rm` (`run`).

5. `.vaultrc` accepts `log-opt`, repeatable, one entry per line, described exactly like `volume`. The value is taken verbatim: no quoting, no expansion.

6. A value that is not `<KEY>=<VALUE>` with a non-empty key — an empty value, a value without `=`, or a value starting with `=` — is a usage error: `invalid value for --log-opt: '<value>'` (exit 2) from the flag, `.vaultrc:<line>: invalid value for log-opt: '<value>'` (exit 1) from the file. This is consistent with `-p`, `-v` and `--env-file`. The part after the `=` may be empty.

7. Beyond that structural check, values are passed verbatim to Docker, which validates the key names and the per-driver values. See Validation.

### Deduplication

The dedupe key is the text before the first `=` (every entry has one, per Semantics point 6). The last occurrence of a key wins and only that entry is emitted, keeping the relative order of the entries that survive. It runs once, in `config_merge`, after both sources have been merged, so a single pass covers flags and `.vaultrc` alike.

Order of operations for `log-opt`: parse > merge (flag list replaces the `.vaultrc` list wholesale) > dedupe by key > one `--log-opt` per surviving entry.

### Precedence

Flags > `.vaultrc` > Docker default. Because a list key is wholesale in `config_merge`, a single `--log-opt` flag replaces every `log-opt=` line of `.vaultrc`; the two sources never contribute to the same merged list. This is the existing rule for `volume`, `port`, `env` and `env-file`, and `log-opt` follows it.

### Status detection

`vault status` gains a `logs:` line, always printed for an existing instance as the **last** line of the block (after `env:`, so no existing line moves), reading `.HostConfig.LogConfig`: the driver, then the options as `KEY=VALUE` sorted by key. The Go template iterates a map in sorted key order, so `max-file` always precedes `max-size`.

Format: `<driver>` when no option is set, else `<driver> <opt>, <opt>`.

### Stale-options hint on `vault up`

When `vault up` finds the instance already running it stays a no-op (exit 0, status block on stdout), but Docker cannot change the log options of an existing container. So, after printing the status block, `up` compares the requested log options with the running ones and warns when they differ:

```
vault: warning: log options differ from the running instance (json-file max-size=1m); run 'vault down' then 'vault up' to apply them
```

1. Requested = the merged, deduped `CONFIG_LOG_OPTS` (flags or `.vaultrc`). Running = the option words of `.HostConfig.LogConfig.Config` (line 7 of the status format). The check is a **subset** check: it warns when any requested `KEY=VALUE` is not present verbatim among the running options (key missing, or different value). Extra running keys are ignored, because Docker merges the host `daemon.json`'s default `log-opts` into the container's config key by key (e.g. `daemon.json` `max-file=3` + `--log-opt max-size=10m` runs with both); a set equality would warn on every `up` on such a host. Consequence: removing a key from `.vaultrc` does not trigger the hint — accepted.
2. The comparison only runs when `CONFIG_LOG_OPTS` is non-empty. Docker can copy a host `daemon.json`'s default options into the container's `LogConfig`, so "nothing requested" vs. "daemon defaults" would otherwise be a false alarm.
3. The parenthesised part is the running instance's `logs:` value (`instance_logs` output).
4. The warning goes to stderr through `output_warning`; the exit code stays 0 and stdout is unchanged.
5. `vault run` needs nothing: it already refuses while the instance is running.
6. The inspect already performed by `instance_status_print` is reused; no extra `docker` call.

### Out of scope

1. **`--log-driver`** (flag or `.vaultrc` key). Options apply to whatever driver is in effect (Docker's default or the host's `daemon.json`); an option the driver does not know fails at `docker run` (exit 1, docker's message). Tracked separately in #83.
2. **Inner services' logs.** The inner `dockerd` and the compose services keep their own logging configuration; bounding those is done in the project's `docker-compose.yml` (as Kerghan already does). This option bounds only the outer container's log.
3. **Applying options to an existing container.** Docker cannot change them in place; a running instance keeps its options until `vault down` + `vault up` recreates it. The CLI only warns (see the stale-options hint) and the guide documents it.
4. **A built-in default bound.** No `max-size` unless the user sets one.
5. **`vault logs` changes.** It still runs `docker logs`; with rotation enabled it shows only what Docker kept.
6. **Global / host-wide configuration.** No `~/.vaultrc` or environment-variable fallback; `log-opt` is per project, like every other key.

### Backward compatibility

1. With no log option anywhere, the `docker run` line is byte-identical to today's.
2. `vault status` keeps every existing line at its position; `logs:` is appended last. Line-indexed parsers (`sed -n 5p`) and label-based parsers (`grep '^ports:'`) both keep working.
3. `vault up` on a running instance keeps its stdout; the stale-options warning goes to stderr and only when log options are requested, so existing callers see an empty stderr as before.
4. New exit-2 cases exist only for the new option; nothing that works today starts failing.
5. Forward compatibility: a `.vaultrc` with `log-opt=` lines read by an older CLI only warns `unknown key 'log-opt'` and runs unbounded — the existing unknown-key rule. Documented in the guide as "requires vault CLI ≥ 0.4.0".
6. The image and in-container code are untouched. CLI and image share the version (`darthjee/vault:<CLI version>`); this ships as a minor bump in the normal release process.
7. No new library file: `scripts/bundle_cli.sh` and `install.sh` are unchanged.

### Performance & security

1. Performance: the dedupe is O(n²) over a handful of entries; the status template gains two lines in the same `docker inspect` call; the stale-options check reuses that call and adds two `sort` subprocesses only on `up` against a running instance with options requested. Rotation itself is Docker's, at negligible cost.
2. Argument injection: each entry is appended as one quoted array element (`CONTAINER_ARGS+=(--log-opt "$item")`), never word-split or evaluated, like `-e`, `-v` and `-p`. A value that looks like a flag (`--privileged=true`) passes the structural check but is consumed by Docker as the value of `--log-opt` and rejected as an unknown option.
3. Secret masking: `vault status` and the stale-options warning print `<key>=***` for any key containing `token`, `password`, `secret` or `credential` (case-insensitive) — relevant when a host `daemon.json` selects a remote driver (`splunk-token=…`). This follows the existing "env keys, never values" rule of `vault status`. `key` is deliberately not a pattern (it would mask non-secret paths such as `gelf-tls-key`).
4. Secrets at rest: `.vaultrc` is usually committed, unlike `.vault.env`; the guide warns against putting credentials in `log-opt` there. Like any `docker run` argument, the values are visible in `docker inspect` and the host process list. The CLI enforces nothing.
5. Guardrails: unchanged; `--log-opt` neither mounts nor publishes anything.

### Runtime privileges & host impact

1. No change to `--privileged` / Sysbox, mounts or ports. Log options are applied by the host `dockerd` outside the container runtime, so they behave identically under `sysbox-runc` and `--privileged`.
2. What gets bounded is the host-side `json-file` of `vault-<name>` (under the host's `/var/lib/docker/containers/<id>/`). The `vault-<name>-data` volume — where the inner `dockerd` keeps its own containers' logs — is **not** bounded by this option (see Out of scope 2). The guide says so explicitly.
3. Host `daemon.json` `log-opts` are merged into the container's config key by key when the driver matches; container options win per key, the others are inherited. `vault status` therefore shows the effective set, and the stale-options hint uses a subset check (see that section).
4. Docker Desktop (macOS) and rootless Docker behave the same; the log file just lives in the VM / the rootless data root. `vault logs -f` follows across rotation (Docker handles it).

## Design decisions

| Decision | Choice | Rationale |

|----------|--------|-----------|

| Commands accepting the option | `up` and `run` only | Same scope as the other value options that reach `docker run`; `down` has nothing to apply it to. |

| Built-in default (`max-size=10m`, `max-file=5`) | None; Docker's default prevails | No behaviour change for existing users. |

| Validation of a value | Structural only: must be `<non-empty key>=<value>`; Docker validates the rest | Catches the realistic typos (`--log-opt max-size 10m`, missing `=`, empty key) as usage errors with a clear message, like `-p`, `-v` and `--env-file`, while keeping a copy of Docker's per-driver option list out of the CLI. |

| Empty value | Usage error, exit 2 (`up`/`run`), exit 1 (`.vaultrc`) | Matches `-p`, `-v` and `--env-file`. |

| Duplicate keys | Dedupe in the CLI by key, last wins, one `--log-opt` per key | A single entry per key on `docker run`, deterministic regardless of source order. |

| `.vaultrc` form | Repeatable `log-opt`, one per line, like `volume` | Consistent with the other list keys. |

| `vault status` | New `logs:` line, last in the block | Answers "why is the disk filling?" without a manual `docker inspect`; shows that the container is on `json-file` with no `max-size`. |

| Log driver itself | Out of scope; no `--log-driver` | The issue asks for log options only. Follow-up: #83. |

| Sensitive option values | Masked as `***` in `vault status` and the warning, by key pattern (`token`, `password`, `secret`, `credential`) | Same principle as "env keys, never values"; matters as soon as a host or #83 selects a remote driver. |

| Changed options on a running instance | Warn on stderr when requested options differ from the running ones; exit 0 | Docker cannot update log options in place; the user otherwise has no signal that the change was ignored. Comparing (rather than warning on every flag) covers `.vaultrc` edits too and avoids false alarms. |

| Guardrails | Unchanged | `--log-opt` publishes no port and mounts nothing. |

| Library layout | No new file | Addition to `args.sh`, `config.sh`, `container.sh`, `instance.sh`, `usage.sh`; `scripts/bundle_cli.sh` needs no change. |

### Edge cases (pinned)

- Empty value, value without `=`, or empty key (`=10m`): exit 2 from the flag, `.vaultrc:<line>: invalid value for log-opt: '<value>'` (exit 1) from the file.

- `--log-opt max-size 10m` (space instead of `=`): `max-size` is rejected as a bad value (exit 2) before `10m` can be taken as `[dir]`.

- Empty option value (`max-size=`): structurally valid, passed to Docker, which decides.

- Duplicate key across sources: the flag replaces the `.vaultrc` list wholesale before dedupe, so the flag wins by replacement, not by key order.

- Duplicate key inside `.vaultrc`: last line wins, first occurrence is dropped.

- A value containing spaces: kept whole, through the array and quoted expansion.

- CRLF line endings in `.vaultrc`: left verbatim in the value, as today.

- `up` on an already running instance: no `docker run` happens, so new log options take effect only after `down` followed by `up` — the existing no-op semantics. When the requested options differ from the running ones, the stale-options hint is printed.

- Running instance with daemon-default options and no log option requested: no comparison, no hint.

- Running instance with daemon-default options plus the requested ones: the requested ones are all present, so no hint.

- A key removed from `.vaultrc` while the instance runs: not detected by the subset check; no hint. Accepted.

- An option value containing spaces: the running options are read back as space-separated words, so such a value can produce a spurious hint. Accepted; the hint is advisory and the exit code is unaffected.

- `run` while the instance is running: the refusal is unchanged and happens before the arguments matter.

- `--log-opt` combined with `--`: `--` ends option parsing, so the token after it is `[dir]`, never a log option.

- `.vaultrc` line `log-opt=max-size=10m`: the line splits at its first `=` (`config.sh`, `key="${line%%=*}"`), so the value is `max-size=10m`.

- `.vaultrc` line `log-opt = max-size=10m` (spaces around `=`): the key is `log-opt ` (trailing space), an unknown key, so the line is skipped with `vault: warning: .vaultrc:<line>: unknown key 'log-opt '`. No trimming is added; this is the existing behaviour for every key.

- Leading whitespace in the value (`--log-opt " max-size=10m"`): passes the structural check (non-empty key ` max-size`), Docker rejects it at start time (exit 1).

- Keys are case-sensitive, like Docker's: `Max-Size=1m` and `max-size=10m` are distinct keys, both are emitted, and Docker rejects the unknown one.

- Values containing template braces (`tag={{.Name}}`): passed verbatim to `docker run`; in `vault status` the Go template prints the stored value as data, not as a template, so `logs:` shows `tag={{.Name}}` literally.

- `up` on a stopped instance: `docker rm`, then a fresh `docker run`, so the new log options apply; no stale-options hint.

- `vault status` on a stopped instance: the `logs:` line is printed, as for a running one.

- Log driver `none` (from the host's `daemon.json`): `vault status` prints `logs:     none`; any `--log-opt` fails at `docker run` (exit 1, docker's message).

- Option combinations the driver rejects (e.g. `max-file` without `max-size` on `json-file`): accepted by the CLI, validated by Docker at start time. The CLI has no per-combination rule.

- `vault run` with log options: they apply to the ephemeral `--rm` container too. Intended, harmless.

- Stale-options hint with duplicate keys: the comparison uses the deduped `CONFIG_LOG_OPTS`, so `--log-opt max-size=1m --log-opt max-size=10m` against a running `max-size=10m` prints no warning.

## Implementation notes

### cli/lib/args.sh

Globals in `_args_reset`:

```bash
ARGS_LOG_OPTS=()
ARGS_LOG_OPTS_SET=0
```

Register the option in `_args_key`, in the group that is valid for `up` and `run`:

```bash
--runtime | -p | --port | -v | --volume | -e | --env | --env-file | --log-opt)
  case "$command" in
    up | run) _args_canonical "$opt" ;;
  esac
  ;;
```

Canonical key in `_args_canonical`:

```bash
--log-opt) echo log-opt ;;
```

Storage in `_args_store`, modelled on the `port` branch — anything but `<non-empty key>=<value>` rejected, value otherwise verbatim:

```bash
log-opt)
  case "$value" in
    ?*=*) ;;
    *) _args_bad_value "$opt" "$value"; return 2 ;;
  esac
  ARGS_LOG_OPTS+=("$value")
  ARGS_LOG_OPTS_SET=1
  ;;
```

Extend the `args_parse` header comment with the two new globals.

### cli/lib/config.sh

`config_reset` adds `CONFIG_RC_LOG_OPTS=()`. `_config_set` adds a branch modelled on `volume`/`env-file`, with no path resolution:

```bash
log-opt)
  case "$value" in
    ?*=*) ;;
    *) _config_bad_value "$number" "$key" "$value"; return 1 ;;
  esac
  CONFIG_RC_LOG_OPTS+=("$value")
  ;;
```

`config_merge` adds the list block plus the dedupe call, after the `CONFIG_ENV_FILES` block:

```bash
if [ "$ARGS_LOG_OPTS_SET" = 1 ]; then
  CONFIG_LOG_OPTS=(${ARGS_LOG_OPTS[@]+"${ARGS_LOG_OPTS[@]}"})
else
  CONFIG_LOG_OPTS=(${CONFIG_RC_LOG_OPTS[@]+"${CONFIG_RC_LOG_OPTS[@]}"})
fi
_config_dedupe_log_opts
```

The helper goes after the public functions and before `_config_pick`. bash 3.2 has no associative arrays, so the lookahead is O(n^2) over a list that is always tiny:

```bash
# Keeps the last occurrence of each log-opt key (the text before the first
# "="; parsing guarantees every entry has one), preserving the order of the
# entries that survive.
# Usage: _config_dedupe_log_opts
# Reads and rewrites CONFIG_LOG_OPTS.
_config_dedupe_log_opts() {
  local i j key later kept=() duplicate
  for ((i = 0; i < ${#CONFIG_LOG_OPTS[@]}; i++)); do
    key="${CONFIG_LOG_OPTS[i]%%=*}"
    duplicate=0
    for ((j = i + 1; j < ${#CONFIG_LOG_OPTS[@]}; j++)); do
      later="${CONFIG_LOG_OPTS[j]%%=*}"
      if [ "$later" = "$key" ]; then
        duplicate=1
        break
      fi
    done
    [ "$duplicate" = 1 ] || kept+=("${CONFIG_LOG_OPTS[i]}")
  done
  CONFIG_LOG_OPTS=(${kept[@]+"${kept[@]}"})
}
```

### cli/lib/container.sh

Insert after the `-e` loop and before the `case "$command"` block:

```bash
for item in ${CONFIG_LOG_OPTS[@]+"${CONFIG_LOG_OPTS[@]}"}; do
  CONTAINER_ARGS+=(--log-opt "$item")
done
```

Extend the `Order:` block of the header comment with a `--log-opt <opt>...` line between `-e <env>...` and `up: --name vault-<name>`. That comment is the contract the tests assert against.

### cli/lib/instance.sh

Append two positional lines to `_instance_status_format`, after the `_instance_env_keys_format` call, so indices 1..5 keep their meaning:

```bash
printf '%s' '{{"\n"}}{{.HostConfig.LogConfig.Type}}{{"\n"}}{{range $k, $v := .HostConfig.LogConfig.Config}}{{$k}}={{$v}} {{end}}'
```

Line 6 is the driver, line 7 the option words. `instance_status_print` reads both and prints the new line last, after the `env` line, so the position of every existing line is unchanged:

```bash
_instance_status_line logs "$(instance_logs "$(_instance_line "$out" 6)" "$(_instance_line "$out" 7)")"
```

New public function, declared after `instance_status_print` and before the private helpers, per the public-before-private rule:

```bash
# Prints "<driver>" when there are no options, else "<driver> <opt>, <opt>".
# Values of sensitive keys (see _instance_mask_log_opts) are printed as "***".
# Usage: instance_logs <driver> <option-words>
instance_logs() {
  local driver="$1" options
  options="$(_instance_join "$(_instance_mask_log_opts "$2")")"
  if [ -z "$options" ]; then
    printf '%s\n' "$driver"
  else
    printf '%s %s\n' "$driver" "$options"
  fi
}
```

The format is positional: adding fields in the middle would renumber the `_instance_line` indices used for the image id and the env keys. Append only.

#### Stale-options hint

`instance_status_print` additionally stores the two raw values it reads, so the caller can reuse them without a second `docker inspect`:

```bash
INSTANCE_LOG_DRIVER="$(_instance_line "$out" 6)"
INSTANCE_LOG_OPTS="$(_instance_line "$out" 7)"
```

(reset to empty for a missing instance; documented in the function's header comment). New public function in `instance.sh`, after `instance_logs`:

```bash
# Warns on stderr when a requested log option (CONFIG_LOG_OPTS) is not
# present, with the same value, among the running instance's options
# (INSTANCE_LOG_OPTS). Extra running keys (daemon.json defaults) are
# ignored. Silent when none are requested. Always returns 0.
# Usage: instance_warn_stale_log_opts
instance_warn_stale_log_opts() {
  local item missing=""
  [ "${#CONFIG_LOG_OPTS[@]}" -gt 0 ] || return 0
  for item in "${CONFIG_LOG_OPTS[@]}"; do
    case " $INSTANCE_LOG_OPTS " in
      *" $item "*) ;;
      *) missing="$item"; break ;;
    esac
  done
  [ -z "$missing" ] && return 0
  output_warning "log options differ from the running instance ($(instance_logs "$INSTANCE_LOG_DRIVER" "$INSTANCE_LOG_OPTS")); run 'vault down' then 'vault up' to apply them"
}
```

`cli/bin/vault` — `vault_up`, `running` branch, after `instance_status_print`:

```bash
running)
  printf '%s is already running\n' "$container"
  instance_status_print "$NAMING_NAME" running || return
  instance_warn_stale_log_opts
  return
  ;;
```

Extend the comment above `vault_up` ("Already running: no-op, prints the status.") with "and warns when the requested log options differ".

#### Masking sensitive option values

Private helper in `instance.sh`, with the other private helpers:

```bash
# Prints the option words with the value of every sensitive key replaced by
# "***". A key is sensitive when it contains token, password, secret or
# credential, case-insensitively.
# Usage: _instance_mask_log_opts <option-words>
_instance_mask_log_opts() {
  local word key lower out=()
  for word in $1; do
    key="${word%%=*}"
    lower="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
      *token* | *password* | *secret* | *credential*) out+=("$key=***") ;;
      *) out+=("$word") ;;
    esac
  done
  printf '%s ' ${out[@]+"${out[@]}"}
}
```

bash 3.2 has no `${var,,}`, hence `tr`. Because `instance_warn_stale_log_opts` builds its parenthesised part through `instance_logs`, the warning is masked too.

### cli/lib/usage.sh

Add under `-e` / `--env-file`:

```
  --log-opt <KEY=VALUE>      Log driver option, repeatable (up, run)
```

### Completions

`cli/completion/vault.bash`: add `--log-opt` to the `up` and `run` lines of `_vault_complete_options`, and to the case list in `_vault_complete_takes_value`. Both carry a comment saying they must stay in sync with `_args_key`.

`cli/completion/_vault`: add to `runtime_opts`:

```zsh
'*--log-opt=[log driver option, repeatable]:KEY=VALUE: '
```

### Documentation

- `docs/guides/vault/cli.md`: a row in the Options table, a `log-opt` row in the `.vaultrc` key table (noting it requires vault CLI ≥ 0.4.0, and that credentials do not belong in a committed `.vaultrc`; masked keys are listed), the `logs:` line (last) in the `vault status` example block, `logs` added to every list of status fields (the quick-reference comment near the top, the `vault status` row of the commands table, and the comment above the example block), and one line in Precedence.

- `docs/guides/vault/cli.md` also notes that only the outer container's log is bounded, not the inner services' logs kept in the `vault-<name>-data` volume, and that host `daemon.json` `log-opts` are merged in per key.

- `docs/agents/flow.md`: the ordered `docker run` list in "CLI flow", step 3.4, and the stale-options warning in the already-running branch of `up`.

- `docs/guides/vault/cli.md` also gets a note under the option: log options apply only when the container is created; on a running instance, `vault down` then `vault up` (and `vault up` warns when they differ).

- Per `docs/agents/contributing.md`, the guide update ships in the same PR as the code.

### Validation

Settled: the CLI checks structure only. A value must match `<non-empty key>=<value>` (the bash pattern `?*=*`); anything else is a usage error (exit 2 from the flag, exit 1 from `.vaultrc`), as `-p`, `-v` and `--env-file` do. Key names and per-driver values are not checked — Docker validates them at `docker run`, and a bad key there is a start failure (exit 1, docker's message). Full validation against a key list was rejected: the list depends on the driver and would go stale with Docker releases. Pure pass-through was rejected: `--log-opt max-size 10m` would silently take `10m` as `[dir]`.

## Testing

### test/cli/args.bats

- "log-opt is repeatable on up and run, values kept in order".

- "log-opt accepts --log-opt=value".

- "log-opt is rejected by down, logs, status and compose" — extend the existing "options outside their command are unknown" case.

- "an empty log-opt value is a bad value" — extend the existing empty-value case.

- "a log-opt value without = is a bad value" — `--log-opt max-size` exits 2 with `invalid value for --log-opt: 'max-size'`.

- "a log-opt value with an empty key is a bad value" — `--log-opt =10m` exits 2.

- "--log-opt max-size 10m is a bad value, not a dir" — exits 2 on `max-size`.

- "nothing given leaves every marker unset" — add `ARGS_LOG_OPTS_SET` and the array length.

### test/cli/config.bats

- Extend "parses every key" with two `log-opt` lines and assert both entries in order; one of them is `log-opt=max-size=10m`, asserting the value keeps its inner `=`.

- Add `log-opt` to the loop of "an empty image, port, volume or env-file fails (exit 1)".

- "log-opt without = or with an empty key fails (exit 1)" — `log-opt=max-size` and `log-opt==10m`, each reporting `.vaultrc:<line>: invalid value for log-opt`.

- "merge: log-opt flags replace the .vaultrc entries".

- "merge: duplicate log-opt keys keep the last one" — `log-opt=max-size=1m` twice, assert one entry.

- "merge: distinct log-opt keys are all kept, in order" — `max-size` and `max-file`, assert both entries.

### test/cli/up.bats and test/cli/run.bats

- Extend the full-argument-list cases:

```bash
assert_docker_called run --privileged --stop-timeout 60 \
  -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
  -p 3000:80 --log-opt max-size=10m --log-opt max-file=5 \
  --name vault-proj -d "$IMAGE"
```

- For `run`, the same block with the log options before `-i`/`-t`/`--rm`.

- "up without --log-opt emits no --log-opt" — guards the unchanged default.

- "a log-opt value with spaces stays one argument" — `--log-opt "max-size=1m --privileged"`; assert the docker call contains exactly `--log-opt` followed by `max-size=1m --privileged` as a single argument, and no standalone `--privileged`.

### test/cli/up.bats — stale-options hint

- "up when running with different log options warns" — stub inspect line 7 as `max-size=1m `, run `up --log-opt max-size=10m`; assert success, unchanged stdout, the warning on stderr, `run` not called.
- "up when running with .vaultrc log options that differ warns" — same via `.vaultrc`.
- "up when running with matching log options is silent" — `max-file=5 max-size=10m ` running, `--log-opt max-size=10m --log-opt max-file=5` requested; stderr empty.
- "up when running with extra daemon-default keys is silent" — running `max-file=3 max-size=10m `, `--log-opt max-size=10m` requested; stderr empty.

- "up when running with duplicate requested keys compares the deduped list" — `--log-opt max-size=1m --log-opt max-size=10m` against running `max-size=10m `; stderr empty.

- "up when stopped applies the log options" — `docker rm`, then `run` with the `--log-opt` entries; no warning.

- "up when running with no log option requested is silent" — running options set (daemon defaults); stderr empty.
- The existing "up when already running" case keeps its empty-stderr assertion.

### test/cli/instance.bats

- `instance_logs` masks `splunk-token=abc`, `Splunk-Password=x`, `aws-secret=y` and `some-credential=z` as `<key>=***`, and leaves `max-size=10m`, `tag={{.Name}}` and `gelf-tls-key=/path` unchanged.

- `instance_warn_stale_log_opts`: silent on empty `CONFIG_LOG_OPTS`, silent on same set in another order, silent when the running set has extra keys, warns on a differing value and on a requested key missing from the running set.

### test/cli/status.bats and the shared fixture

- "status shows the log driver and its options" and "status shows the bare driver when no option is set".

- "status shows the logs line for a stopped instance".

- "status prints template-like option values literally" — line 7 stubbed as `tag={{.Name}} `, asserts `logs:     json-file tag={{.Name}}`.

- The two new positional lines change the shared `STATUS_FORMAT` fixture used by the status assertions in `up.bats` ("up when already running") and `status.bats`. That fixture must gain the driver and option lines, otherwise every existing status assertion breaks. This is the main ripple of the change.

### test/cli/completion.bats

- `--log-opt` is offered for `up` and `run`, and not for `down`, `logs`, `status` or `compose`.

### scripts/test_cli_e2e.sh

- Add `--log-opt max-size=10m --log-opt max-file=2` to the `vault up` call, and in `cli_status` assert that the `logs:` line contains both `max-file=2` and `max-size=10m` (a containment check, so a CI host's `daemon.json` defaults do not break it). This is the only test proving that real Docker accepts the generated `docker run` line and that the status template parses a real `LogConfig`.

### CI

`cli/` and `docs/` are both touched, so before opening the PR: `make lint`, `make test`, `make test-docs`, `make test-cli-e2e`.

## Context

- Issue #81 in `darthjee/vault`, opened 2026-11-25 by `darthjee`, state open, status Backlog, no comments, labels `Feature`, `shipit`, `Writting`.

- Origin: `darthjee/kerghan#596`. The Kerghan standalone distribution runs on Vault, already bounds the inner services' logs, and wants the outer container's log bounded too.

- Affected module: the host-side CLI under `cli/`, plus the two completions and the guides.

- Documents read for this specification: [AGENTS.md](https://github.com/darthjee/vault/blob/main/AGENTS.md), [docs/agents/architecture.md](https://github.com/darthjee/vault/blob/main/docs/agents/architecture.md), [docs/agents/flow.md](https://github.com/darthjee/vault/blob/main/docs/agents/flow.md), [docs/agents/contributing.md](https://github.com/darthjee/vault/blob/main/docs/agents/contributing.md), [docs/guides/vault/cli.md](https://github.com/darthjee/vault/blob/main/docs/guides/vault/cli.md), [docs/guides/vault/configuration.md](https://github.com/darthjee/vault/blob/main/docs/guides/vault/configuration.md).

- Code read for this specification: [cli/bin/vault](https://github.com/darthjee/vault/blob/main/cli/bin/vault), [cli/lib/args.sh](https://github.com/darthjee/vault/blob/main/cli/lib/args.sh), [cli/lib/config.sh](https://github.com/darthjee/vault/blob/main/cli/lib/config.sh), [cli/lib/container.sh](https://github.com/darthjee/vault/blob/main/cli/lib/container.sh), [cli/lib/instance.sh](https://github.com/darthjee/vault/blob/main/cli/lib/instance.sh), [cli/lib/usage.sh](https://github.com/darthjee/vault/blob/main/cli/lib/usage.sh), [cli/lib/naming.sh](https://github.com/darthjee/vault/blob/main/cli/lib/naming.sh), [cli/lib/guardrails.sh](https://github.com/darthjee/vault/blob/main/cli/lib/guardrails.sh), [scripts/bundle_cli.sh](https://github.com/darthjee/vault/blob/main/scripts/bundle_cli.sh), [cli/completion/vault.bash](https://github.com/darthjee/vault/blob/main/cli/completion/vault.bash), [cli/completion/_vault](https://github.com/darthjee/vault/blob/main/cli/completion/_vault), [test/cli/args.bats](https://github.com/darthjee/vault/blob/main/test/cli/args.bats), [test/cli/config.bats](https://github.com/darthjee/vault/blob/main/test/cli/config.bats), [test/cli/up.bats](https://github.com/darthjee/vault/blob/main/test/cli/up.bats), [test/cli/run.bats](https://github.com/darthjee/vault/blob/main/test/cli/run.bats).

- Not read: `test/cli/status.bats` and `test/cli/completion.bats` (paths confirmed to exist in the repository listing, contents not verified).
