# Install library and its bats tests
Add `source/lib/install.sh`, following the existing library rules: sourcing it only defines
functions, and each function has a short header comment with a `# Usage:` line, like
`source/lib/images.sh`. It provides one public function that copies the CLI and the completions
from a source layout into a target dir, so it can be unit-tested without the image:

- `install_copy <bin> <completion_dir> <target>`:
  - fails with `vault-install: error: <target> is not writable` on stderr and returns 1 when
    `<target>` is missing, is not a directory, or is not writable (`[ -d ] && [ -w ]`);
  - copies `<bin>` → `<target>/vault` and `chmod 0755`;
  - `mkdir -p <target>/completion`, copies `vault.bash` and `_vault` from `<completion_dir>` and
    `chmod 0644`;
  - returns 1 if any copy fails; prints nothing on success.

Only `cp`, `mkdir` and `chmod`. No `docker`, no `dockerd`.

Add `test/lib/install.bats`, modelled on the existing `test/lib/*.bats`: source the library and
use `$BATS_TEST_TMPDIR` for a fake source layout and target. Cover:
- a successful copy: the files exist, `vault` has mode 0755, the completions have mode 0644, and there is no output;
- overwriting an existing `vault` (an upgrade);
- a missing target and a read-only target (`chmod 0555`) → exact error message, status 1.
  Skip the read-only case when running as root (`[ "$(id -u)" -eq 0 ]`), since root ignores the mode bits.

## Files to Change
- `source/lib/install.sh` — new library with `install_copy`.
- `test/lib/install.bats` — new unit tests.
