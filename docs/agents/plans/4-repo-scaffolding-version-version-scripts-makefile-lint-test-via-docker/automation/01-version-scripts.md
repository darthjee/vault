# VERSION and version scripts
- Create `VERSION` containing `0.1.0`.
- Add `scripts/bump_version.sh X.Y.Z`:
  - Validate the argument against `^[0-9]+\.[0-9]+\.[0-9]+$`.
  - Write `VERSION`.
  - Rewrite the README `**Current Version:**` line through a temp file.
  - Resolve the repo root from the script's location.
- Add `scripts/check_tag_version.sh X.Y.Z`:
  - Fail when the argument is missing.
  - Compare the tag with the trimmed contents of `VERSION` and with the README line.
  - On a mismatch, exit non-zero with a message naming the source that doesn't match.
- Both scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`, and must pass shellcheck.

## Files to Change
- `VERSION`: new file.
- `scripts/bump_version.sh`: new file.
- `scripts/check_tag_version.sh`: new file.
