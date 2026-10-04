# Install entry `vault-install`
Add `source/bin/install.sh`, an entry point like `source/bin/entrypoint.sh`:
`#!/usr/bin/env bash`, `set -euo pipefail`, constants at the top, and the library sourced from
`/usr/local/lib/vault/install.sh` (with the `# shellcheck source=/dev/null` pragma used in the entrypoint).

- It takes no arguments. If it gets any, ignore them; the spec fixes the call shape.
- It calls
  `install_copy /usr/local/bin/vault /usr/local/share/vault/completion /install`
  and exits with its status: 0 silently on success, 1 with the message on failure.
- It never sources `dockerd.sh` / `signals.sh` and never starts `dockerd`.

It runs as an arbitrary host uid/gid (`--user`), so it must not depend on `$HOME`, on a passwd
entry, or on writing anywhere except `/install`.

## Files to Change
- `source/bin/install.sh` — new in-image install entry.
