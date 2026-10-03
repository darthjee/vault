# Stamp and check VAULT_VERSION
- `scripts/bump_version.sh`: also rewrite the `VAULT_VERSION="…"` line of `cli/bin/vault`, and of
  `install.sh` when the file exists. Fail before writing anything if a target file has no such
  line or more than one. Keep file modes (copy contents back, as done for the README).
- `scripts/check_tag_version.sh`: also fail unless the `VAULT_VERSION` line of `cli/bin/vault`
  (and of `install.sh` when it exists) equals the tag; a missing or duplicated line fails with
  its own message.

#26 removes the "when it exists" for `install.sh`.

## Files to Change
- `scripts/bump_version.sh` — stamp `VAULT_VERSION`.
- `scripts/check_tag_version.sh` — check `VAULT_VERSION`.
