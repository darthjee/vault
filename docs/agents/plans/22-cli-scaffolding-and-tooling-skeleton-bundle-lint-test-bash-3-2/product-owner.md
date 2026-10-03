# Product-owner Plan: CLI scaffolding and tooling: skeleton, bundle, lint/test, bash 3.2

Main plan: [plan.md](plan.md)

## Shared contracts

- **Version line:** exactly one line in `cli/bin/vault` matching
  `^VAULT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$` (column 0, double quotes), set to the current
  `VERSION`.
- **Lib block markers:** two lines, exactly `# BEGIN LIBS` and `# END LIBS`, at column 0, once
  each, in that order. Between them, only the `source` lines for the libraries.
- **Library list and bundle order:** `cli/lib/output.sh`, then `cli/lib/usage.sh`. Both only
  define functions, prefixed by module (`output_*`, `usage_*`).
- **Bundle path:** `build/vault`, mode `0755`, built by `scripts/bundle_cli.sh` (`make bundle-cli`).
- **Tests against the bundle:** `scripts/test.sh` runs `scripts/bundle_cli.sh` before any bats
  run, so `build/vault` exists when `test/cli/` runs. Tests reach it at
  `$BATS_TEST_DIRNAME/../../build/vault` and the source at `$BATS_TEST_DIRNAME/../../cli/bin/vault`.
- **bats helpers:** both `BATS_IMAGE` and `BASH32_TEST_IMAGE` provide `bats-support` and
  `bats-assert` through `bats_load_library`, as `test/lib/*.bats` already uses.
- **bash 3.2 suites:** `BASH32_TEST_IMAGE` runs `test/cli/` and `test/install/` (whichever have
  `.bats` files); `test/lib/` runs on `BATS_IMAGE` only.

## Implementation Steps

### Step 1 — Record the issue's decisions in the spec
Update `docs/agents/specs/` so it matches what #22 ships:

- [cli-overview.md](../../specs/cli-overview.md): open point 7 settled ("No", settled by #22);
  `cli/lib/*.sh` names (`output.sh`, `usage.sh`) for the skeleton.
- [cli-tooling.md](../../specs/cli-tooling.md):
  - the version scripts handle `install.sh` only when it exists, until #26;
  - the bundle list and order (`output.sh`, `usage.sh`);
  - wiring `bundle-cli` into `build-image` / `test-image` / `release` is done by #26;
  - the `BASH32_TEST_IMAGE` default (`vault-bash32-test:local`) and the pinned bats-core tag;
  - `test/lib/` is not run on bash 3.2.
- [cli-overview.md → Sub-issue map](../../specs/cli-overview.md#sub-issue-map): #26 also wires
  `bundle-cli` into the image targets and makes `install.sh` mandatory in the version scripts.

Use the final values from `automation` and `cli` if they differ from this plan.

## Files to Change
- `docs/agents/specs/cli-overview.md` — open point 7, library names, sub-issue map.
- `docs/agents/specs/cli-tooling.md` — version scripts, bundle order, image targets, bash 3.2 image.

## CI Checks
- `docs/`: none in CI; check links by hand.

## Notes
- Specs are a working document; keep wording short and in the existing style.
