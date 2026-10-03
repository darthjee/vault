# Add the bundle script and make target
`scripts/bundle_cli.sh` builds `build/vault` from `cli/bin/vault`:

- the fixed library list lives in the script: `output.sh`, `usage.sh`;
- fail (non-zero, message on stderr) when:
  - `# BEGIN LIBS` or `# END LIBS` is missing or appears more than once, or END comes before BEGIN;
  - a listed library is missing, or `cli/lib/` holds a `.sh` file not in the list;
- replace the block (markers included) with the libraries' content, in list order;
- write to a temp file, then move it to `build/vault` with mode `0755` (create `build/`).

Add a `bundle-cli` target (`.PHONY`) calling the script, and add `build/` to `.gitignore`.

## Files to Change
- `scripts/bundle_cli.sh` — new; bundle builder.
- `Makefile` — `bundle-cli` target.
- `.gitignore` — ignore `build/`.
