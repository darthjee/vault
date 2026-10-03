# Issue: CLI scaffolding and tooling: skeleton, bundle, lint/test, bash 3.2

## Description
Part of epic #20 (Vault CLI). Depends on #21 (CLI spec). Follow `docs/agents/specs/*.md`, mainly
[cli-tooling.md](../specs/cli-tooling.md) and [cli-ci.md → PR pipeline](../specs/cli-ci.md#pr-pipeline).

Agents:
- `cli`: the skeleton under `cli/` and the bats tests under `test/cli/`;
- `automation`: the Makefile, `scripts/`, `test/bash32/`, `.circleci/` and the `build/` git-ignore entry;
- `product-owner`: the spec updates listed under [Spec updates](#spec-updates).

### Decisions
- **`install.sh` absent:** until #26 adds it, `bump_version.sh` and `check_tag_version.sh` handle
  `install.sh` only when the file exists. #26 makes it mandatory.
- **Open point 7:** `test/lib/` does **not** run under bash 3.2. Only `test/cli/` and
  `test/install/` do; the image ships a current bash.
- **Image targets:** #22 does not make `build-image` / `test-image` / `release` depend on
  `bundle-cli`. #26 wires that when the Dockerfile starts copying `build/vault`.
- **Skeleton scope:** command dispatch, `version`, `help`, and the unknown-command error.
  Libraries: `cli/lib/output.sh` (diagnostic helpers) and `cli/lib/usage.sh` (usage text), in
  that bundle order.

## Problem
There is no CLI code yet, and no tooling around it:
- no bundle step;
- no lint or test coverage of `cli/`;
- no bash 3.2 test run;
- no version stamping of the CLI.

Every later CLI PR (#23–#28) needs this in place to be linted, tested and bundled from the start.

## Expected Behavior
### CLI skeleton (`cli`)
- `cli/bin/vault`:
  - shebang `#!/usr/bin/env bash`, bash 3.2 compatible;
  - exactly one `VAULT_VERSION="X.Y.Z"` line at column 0, stamped from `VERSION`;
  - one `# BEGIN LIBS` … `# END LIBS` block sourcing `cli/lib/*.sh` relative to `cli/bin/vault`;
  - `vault version` prints `vault X.Y.Z` to stdout, exit 0;
  - `vault help`, `-h` and `--help` print the usage to stdout, exit 0;
  - an unknown command prints `vault: error: unknown command '<command>'` then
    `vault: hint: run "vault help"` to stderr, exit 2.
- `cli/lib/output.sh`: helpers that print `vault: error: `, `vault: warning: ` and `vault: hint: `
  lines to stderr (functions only, prefixed by module).
- `cli/lib/usage.sh`: the usage text.

### Bundle (`automation`)
- `scripts/bundle_cli.sh` and `make bundle-cli` build `build/vault` (mode `0755`) by replacing the
  marked block with `cli/lib/*.sh` in a fixed order listed in the script.
- It fails on missing, duplicated or out-of-order markers, and on a file in `cli/lib/` missing
  from (or extra to) its list.
- `build/` is git-ignored.

### Lint and test (`automation`)
- `make lint` also covers `cli/bin/vault`, `cli/lib/*.sh`, `cli/completion/vault.bash`, `install.sh`,
  `test/cli/` and `test/install/`, whichever exist.
- `make test` runs:
  - `test/lib/`, `test/cli/`, `test/install/` on `BATS_IMAGE`;
  - `test/cli/`, `test/install/` on `BASH32_TEST_IMAGE`, built from `test/bash32/Dockerfile`
    (`FROM bash:3.2` + bats-core at a pinned tag).
- `BASH32_TEST_IMAGE` is a new Make variable with a local default tag (chosen by `automation`).

### Version stamping (`automation`)
- `scripts/bump_version.sh` also updates the `VAULT_VERSION` line of `cli/bin/vault`, and of
  `install.sh` when it exists.
- `scripts/check_tag_version.sh` also fails unless the `VAULT_VERSION` line of `cli/bin/vault`
  (and of `install.sh` when it exists) matches the tag; a missing or duplicated line fails.

### CI (`automation`)
- The `build-and-test` job runs `make bundle-cli` after `make test`, before `make test-image`.

### Tests (`cli`)
- Bats tests under `test/cli/` for `version`, `help`, `-h` / `--help` and the unknown command,
  asserting the spec's wording and exit codes, against both the source tree and `build/vault`.
- `make lint`, `make test` and `make bundle-cli` pass.

### Spec updates (`product-owner`)
In the same PR, per [cli-overview.md → Status](../specs/cli-overview.md#status-of-this-document):
- open point 7 settled as "No";
- `install.sh` handled only when present until #26;
- library names and bundle order (`output.sh`, `usage.sh`);
- `bundle-cli` wiring into the image targets moved to #26;
- the `BASH32_TEST_IMAGE` default.

## Benefits
- Later CLI sub-issues start with lint, bash 3.2 tests and the bundle already wired in.
- bash 4+ features cannot creep into the CLI.
- The CLI version cannot drift from `VERSION`.
