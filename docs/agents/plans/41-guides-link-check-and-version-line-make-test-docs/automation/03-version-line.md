# Guides version line in bump/check scripts

- `scripts/bump_version.sh`:
  - add `GUIDES_FILE="$ROOT/docs/guides/vault.md"` and
    `GUIDES_VERSION_REGEX='^\*\*Vault version:\*\* [0-9]+\.[0-9]+\.[0-9]+$'`;
  - before writing anything, fail when the file is missing (`error: docs/guides/vault.md not
    found`), has no line (`error: no '**Vault version:**' line found in docs/guides/vault.md`)
    or more than one (`error: N '**Vault version:**' lines found in docs/guides/vault.md
    (expected 1)`);
  - rewrite it with the existing `rewrite` helper:
    `-E "s/${GUIDES_VERSION_REGEX}/**Vault version:** ${new_version}/"` (escape the `*` in the
    replacement as needed);
  - update the header comment.
- `scripts/check_tag_version.sh`:
  - same constants; missing file, zero or several lines → error and `status=1`; otherwise
    compare the version to the tag (`error: tag 'X' does not match docs/guides/vault.md Vault
    version ('Y')`);
  - success message: `Tag X matches VERSION, README.md, docs/guides/vault.md, cli/bin/vault and
    install.sh`; update the header comment.

Keep the style close to the existing `VAULT_VERSION` handling (a small helper is fine if it
removes duplication).

## Files to Change

- `scripts/bump_version.sh` — handle the guides version line.
- `scripts/check_tag_version.sh` — validate the guides version line.
