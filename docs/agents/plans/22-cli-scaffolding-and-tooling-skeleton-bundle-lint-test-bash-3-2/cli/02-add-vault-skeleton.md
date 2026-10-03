# Add the cli/bin/vault skeleton
Create the CLI main, executable (mode `0755`), with shebang `#!/usr/bin/env bash`:

1. The `VAULT_VERSION="X.Y.Z"` line (value from `VERSION`).
2. The `# BEGIN LIBS` … `# END LIBS` block sourcing `output.sh` then `usage.sh`, resolving
   `cli/lib/` relative to the script (e.g. `cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd`),
   so the source tree runs as is. Add shellcheck `source=` directives so `make lint` can follow them.
3. Dispatch on the first argument:
   - `version` → `vault $VAULT_VERSION` on stdout, exit 0;
   - `help`, `-h`, `--help` → `usage_print`, exit 0;
   - no argument → usage on **stderr**, exit 2 ([cli-commands.md → Syntax](../../../specs/cli-commands.md#syntax));
   - anything else → `output_error "unknown command '<command>'"`, then
     `output_hint 'run "vault help"'`, exit 2.

Keep dispatch in small functions so #23/#24 can add commands without restructuring.

## Files to Change
- `cli/bin/vault` — new; CLI main.
