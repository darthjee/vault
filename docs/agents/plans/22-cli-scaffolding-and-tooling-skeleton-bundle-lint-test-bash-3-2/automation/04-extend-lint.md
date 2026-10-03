# Extend make lint
`scripts/lint.sh` also covers, whichever exist:

- `cli/bin/vault` (no `.sh` extension — add it by path);
- `cli/lib/*.sh`, `cli/completion/vault.bash`;
- `install.sh`;
- `test/cli/`, `test/install/` (already under `test/`, so check they are picked up).

Make sure shellcheck can follow the `source` lines in `cli/bin/vault` (e.g. `-x` or the
directives added by `cli`).

## Files to Change
- `scripts/lint.sh` — CLI paths.
