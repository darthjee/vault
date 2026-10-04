# Bats tests

Under `test/scripts/` (run by `make test` on `BATS_IMAGE`; the repo is mounted read-only, so
work in `$BATS_TEST_TMPDIR`). Follow `test/scripts/github_release.bats` for setup
(`bats_load_library bats-support` / `bats-assert`, `run --separate-stderr`).

- `check_guides_links.bats`: build fixture trees in `$BATS_TEST_TMPDIR` (written inline with
  heredocs, or under `test/scripts/fixtures/guides/`), run the script with the tree as argument:
  - passing tree: `vault.md` + `vault/cli.md` with relative links both ways, `../vault.md`,
    same-page `#anchor`, cross-page `cli.md#some-heading`, `https://` links → success, `OK`
    line;
  - duplicate headings: `#setup-1` resolves, `#setup-2` fails when only two exist;
  - headings with punctuation (`` `.vaultrc` and `.vault.env` `` → `vaultrc-and-vaultenv`);
  - each failure kind, asserting the file, message and link on stderr and exit 1: leaves the
    tree (`../../README.md`), missing file, missing anchor (same page and other page),
    `http://`, absolute path `/etc/hosts`, `mailto:`, reference definition, image link;
  - several problems in one run are all reported;
  - links inside fenced code blocks and inline code are ignored;
  - empty root and missing root → success.
- `bump_version.bats`: copy `scripts/`, `VERSION`, `README.md`, `cli/bin/vault`, `install.sh`
  and `docs/guides/vault.md` into a temp work tree; assert all lines (including the guides line)
  become the new version; missing guides file, no line, two lines → failure and **no file
  changed**; invalid / missing version argument → usage errors.
- `check_tag_version.bats`: same temp copy; matching tag → success message; a mismatch in the
  guides line, a missing guides file, zero or two lines → failure naming
  `docs/guides/vault.md`; existing VERSION/README/VAULT_VERSION mismatches still fail.
- Update `test/scripts/` description where it appears in script headers, if any.

## Files to Change

- `test/scripts/check_guides_links.bats` — new.
- `test/scripts/bump_version.bats` — new.
- `test/scripts/check_tag_version.bats` — new.
- `test/scripts/fixtures/…` — optional fixture trees.
