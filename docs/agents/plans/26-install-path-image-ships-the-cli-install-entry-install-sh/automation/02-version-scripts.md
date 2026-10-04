# Make install.sh required in the version scripts
#26 makes `install.sh` required ([cli-tooling.md → Version line](../../../specs/cli-tooling.md#version-line)):

- `scripts/bump_version.sh`: always include `install.sh` in `version_files`. A missing file fails
  with `error: install.sh not found`, before anything is written.
- `scripts/check_tag_version.sh`: always call `check_vault_version "$INSTALL_FILE"`. The success
  message is always `Tag X matches VERSION, README.md, cli/bin/vault and install.sh`.
- Update both header comments: drop "(when it exists)".

If there are tests or bats cases for these scripts, update them. Otherwise check by hand:
`make check-version-tag TAG=0.0.1` passes, and a temporary copy without `install.sh` fails.

## Files to Change
- `scripts/bump_version.sh` — `install.sh` required.
- `scripts/check_tag_version.sh` — `install.sh` required.
