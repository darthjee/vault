# Instance naming

Implement [cli-commands.md → Instance naming](../../../specs/cli-commands.md#instance-naming).

- `cli/lib/naming.sh`:
  - `naming_from_image <image>`: drops registry and path (everything up to the last `/`),
    then the digest (`@…`) and tag (`:…` after the last `/`), e.g.
    `registry.example.com:5000/team/my-app:1.0` → `my-app`;
  - `naming_sanitize <base>`: lowercase via `tr`, then delete everything outside
    `[a-z0-9_.-]` (`My App!` → `myapp`);
  - `naming_valid <name>`: matches `[a-z0-9][a-z0-9_.-]*`;
  - `naming_resolve <explicit-name> <image-flag-given> <image> <dir-given> <dir>`: explicit
    name (flag or `.vaultrc`, already validated) wins; else image-derived when `--image` was
    given without `[dir]`; else the basename of the dir (the caller passes `$PWD` when no
    `[dir]`); derived names are sanitized; an empty result →
    `cannot derive an instance name from '<base>'` + `pass --name <name>` hint, return 2;
  - `naming_container <name>` → `vault-<name>`; `naming_volume <name>` → `vault-<name>-data`.
- `image=` from `.vaultrc` never feeds the image-derived default (only `--image` does).

## Files to Change
- `cli/lib/naming.sh` — new: naming rules.
- `test/cli/naming.bats` — new: image parsing (registry with port, path, tag, digest),
  sanitizing, empty result error + hint + exit 2, precedence of the sources, container and
  volume names.
