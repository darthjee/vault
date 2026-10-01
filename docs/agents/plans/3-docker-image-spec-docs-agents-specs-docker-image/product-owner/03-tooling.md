# Write tooling.md
Create `docs/agents/specs/docker-image/tooling.md`. It links to `contributing.md` (Bash style, CI Checks, Dependency Injection), then adds:
- **Versioning:** `VERSION` (`0.1.0`), `scripts/bump_version.sh X.Y.Z` (updates `VERSION` and the README line), `scripts/check_tag_version.sh`.
- **Make as the only entry point:**
  - each target with its behaviour and exit codes;
  - logic beyond a one-line recipe lives in `scripts/*.sh`;
  - CI-only steps live in `scripts/ci/*.sh`;
  - everything is shellchecked.
- **Lint and unit tests:**
  - `SHELLCHECK_IMAGE ?= koalaman/shellcheck:v0.11.0` and `BATS_IMAGE ?= bats/bats:1.14.0`, used directly with the repo mounted read-only;
  - `make lint` covers `source/`, `scripts/` and `test/`;
  - `make test` covers `test/lib/`, one bats file per library, with `docker` / `dockerd` stubbed;
  - helper libraries come from the bats image (#4 verifies); the fallback is to vendor them under `test/helpers/`;
  - known gap: tests run on the bats image's bash, not on the Vault image's runtime.
- **Smoke test (`make test-image`):**
  - build the image;
  - run it `--privileged` with the fixture compose file;
  - `curl` the published port;
  - assert nothing listens on 2375;
  - `docker stop` exits cleanly with code 0;
  - cleanup always runs.
- **Not covered by CI:** Sysbox and arm64 at runtime.

## Files to Change
- `docs/agents/specs/docker-image/tooling.md` — new.
