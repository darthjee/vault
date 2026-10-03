# .vaultrc, precedence and .vault.env

Implement [cli-config.md](../../../specs/cli-config.md).

- `cli/lib/config.sh`:
  - `config_parse <vaultrc-dir>`: reads `.vaultrc` lines from **stdin** with
    `while IFS= read -r line || [ -n "$line" ]` (keeps the last line without a newline, no
    trimming), counting lines from 1:
    - blank lines and lines starting with `#` are skipped;
    - a line without `=` → `.vaultrc:<line>: expected key=value`, return 1;
    - key = text before the first `=`, value = everything after it, verbatim;
    - known keys: `name`, `image`, `runtime`, `stop-timeout` (scalars, last wins) and `port`,
      `volume`, `env`, `env-file` (append to `CONFIG_*` arrays, file order);
    - invalid values (`name` pattern, `runtime` set, `stop-timeout` positive integer) →
      `.vaultrc:<line>: invalid value for <key>: '<value>'`, return 1; `env` is never
      validated nor echoed;
    - unknown key → `.vaultrc:<line>: unknown key '<key>'` warning, skipped;
    - relative `volume` sources and `env-file` paths are resolved against `<vaultrc-dir>`
      (a `volume` source is relative when it starts with `.` or contains `/` without a leading
      `/`; a bare name is a named volume and stays as is — document the rule in a comment and
      in the PR as a spec clarification);
    - a guardrail failure on a `.vaultrc` entry is raised by step 05 on the merged values.
  - `config_merge`: applies **flags > `.vaultrc` > defaults** into `CONFIG_*` final values:
    scalars by presence; list keys replaced per key when the flag was given at all; port
    default `3000:80` only when neither source gives a port; defaults image
    `darthjee/vault:$VAULT_VERSION` (passed in), runtime `auto`, stop timeout `60`.
  - `config_vault_env <dir> <exists>`: the caller (`bin/vault`) tests `[ -f "$dir/.vault.env" ]`;
    when it exists, it is placed before every `env-file`/`--env-file`, and a `--env-file` flag
    never replaces it. Its content is never read.
- A missing `.vaultrc` is not an error (`bin/vault` simply does not call the parser).

## Files to Change
- `cli/lib/config.sh` — new: stdin parser, merge, `.vault.env` placement.
- `test/cli/config.bats` — new: here-doc fed parsing (comments, blank lines, `=` in values,
  spaces in values, no trailing newline, CRLF left verbatim), each error/warning with its line
  number and exit code, last-wins scalars, repeatable keys, relative path resolution,
  precedence (flags replace per key, port default), `.vault.env` ordering (edge case 12).
