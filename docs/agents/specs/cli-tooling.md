# CLI Spec: Tooling

Part of the CLI spec for epic #20. Index: [cli-overview.md](cli-overview.md). Implemented in #22
(version line, bundle, lint/test, bash 3.2) and #27 (`test-cli-e2e`).

## Version line

- `cli/bin/vault` and `install.sh` each contain exactly one line, at column 0:

  ```bash
  VAULT_VERSION="X.Y.Z"
  ```

- The bundle `build/vault` keeps that line unchanged (it comes from `cli/bin/vault`).
- The CLI's default image is `darthjee/vault:$VAULT_VERSION`, and `vault version` prints
  `vault $VAULT_VERSION`.
- `VERSION` stays the single source: the line is stamped from it, never edited by hand.

| Script | Rule |
|--------|------|
| `scripts/bump_version.sh X.Y.Z` (`make bump-version`) | Updates `VERSION`, the README `**Current Version:**` line, and the `VAULT_VERSION="…"` line in `cli/bin/vault` and `install.sh`. |
| `scripts/check_tag_version.sh X.Y.Z` (`make check-version-tag`) | Fails unless the tag equals `VERSION`, the README line, and the `VAULT_VERSION` line of **both** `cli/bin/vault` and `install.sh`. A missing or duplicated line fails. |

`install.sh` reads a caller-supplied `VAULT_VERSION` before its stamped line
([cli-install.md → Environment](cli-install.md#environment)).

## Bundling rule

- `cli/bin/vault` sources the libraries through **one** marked block:

  ```bash
  # BEGIN LIBS
  ...source lines for cli/lib/*.sh...
  # END LIBS
  ```

  The source lines resolve `cli/lib/` relative to `cli/bin/vault`, so the source tree runs
  as is (tests run against it).
- `scripts/bundle_cli.sh` replaces that block (markers included) with the content of
  `cli/lib/*.sh`, concatenated in a **fixed order** listed in the script (not glob order), and
  writes the result to `build/vault` with mode `0755`.
- The script fails when the markers are missing, duplicated or out of order, or when a file in
  `cli/lib/` is missing from (or extra to) its list.
- The bundle is self-contained: it sources nothing at run time.
- Libraries only define functions, so concatenating them has no side effects.
- `cli` keeps the block and the libraries compatible with the rule; `automation` owns the script.
- The list order and the library file names are chosen by #22 / #23.

## Make targets and scripts

| Target | Script | Behaviour |
|--------|--------|-----------|
| `bundle-cli` | `scripts/bundle_cli.sh` | Builds the single executable `build/vault` (git-ignored). |
| `lint` | `scripts/lint.sh` | shellcheck, extended to the CLI (see [coverage](#lint-and-test-coverage)). |
| `test` | `scripts/test.sh` | Runs bats on both the current `BATS_IMAGE` and the bash 3.2 image. |
| `test-cli-e2e` | `scripts/test_cli_e2e.sh` | End-to-end test against the built image and bundle (see [testing strategy](#testing-strategy)). |
| `github-release TAG=x` | `scripts/github_release.sh` | Creates the GitHub release and uploads the assets. Fails fast without `TAG`. See [cli-ci.md](cli-ci.md). |

- Existing targets keep their names and behaviour; `test` and `lint` are extended.
- Every target that builds the image (`build-image`, and so `test-image`; `release`) runs
  `bundle-cli` first, because the Dockerfile copies `build/vault`.
- `test-cli-e2e` builds the image and the bundle itself (it may depend on `build-image` and
  `bundle-cli`).
- New variable:

  | Variable | Purpose |
  |----------|---------|
  | `BASH32_TEST_IMAGE` | Tag of the bash 3.2 test image, built from `test/bash32/Dockerfile` (`FROM bash:3.2` + bats-core at a pinned tag). Its default value is chosen by #22. |

- Exact recipes, dependencies between targets and script internals are left to #22, #27 and
  #28. Make stays the only entry point.

## Lint and test coverage

| Check | Covers |
|-------|--------|
| `make lint` (shellcheck) | Existing paths, plus `cli/bin/vault`, `cli/lib/*.sh`, `cli/completion/vault.bash`, `install.sh`, `test/cli/`, `test/install/`. |
| `make test` on `BATS_IMAGE` | `test/lib/`, `test/cli/`, `test/install/`. |
| `make test` on `BASH32_TEST_IMAGE` | `test/cli/`, `test/install/` (and `test/lib/` if #22 decides so; open point 7). |
| zsh syntax | `zsh -n cli/completion/_vault` (runner chosen by #25; open point 8). |

## Testing strategy

1. **Unit (bats, no real Docker):**
   - a stub `docker` placed first on `PATH` records its arguments and returns scripted output
     (`docker info` runtimes and security options, `inspect` state, failures);
   - tests assert the exact `docker` argument list for each combination of flags, `.vaultrc`,
     `.vault.env` and runtime;
   - every edge case ([cli-commands.md → Edge cases](cli-commands.md#edge-cases)) and every
     message ([cli-commands.md → Messages](cli-commands.md#messages)) has a test, asserting the
     spec's wording and exit code;
   - `vault version` / `vault help` run against both the source tree and `build/vault`.
2. **bash 3.2:** the same CLI suites run on `BASH32_TEST_IMAGE`, so bash 4+ features cannot creep
   in.
3. **Completion:** bats checks that the bash completion function offers the subcommands and the
   main options; `_vault` is syntax-checked with `zsh -n`.
4. **`install.sh`:** bats under `test/install/` with the stub `docker`: env vars and defaults,
   the not-writable and not-in-`PATH` cases, the version override.
5. **End-to-end (`make test-cli-e2e`, real Docker, `--privileged` only):**
   - builds the image and the bundle;
   - runs `build/vault up` with `--image` set to the freshly built tag and `--runtime=privileged`
     forced (no Sysbox in CI), against the test compose fixture (`test/fixture/`);
   - `curl`s the published port, then runs `status` and `compose ps`, then `down`, and checks a
     clean shutdown;
   - runs `install.sh` with `VAULT_IMAGE` set to the local build and `VAULT_INSTALL_DIR` set to
     a temp dir, then checks that the installed `vault version` prints `vault <VERSION>` and
     that the file is owned by the current user;
   - cleans up its container, volume and temp dirs, even on failure.

The list of test cases is left to each sub-issue.
