# Add the scripts agent

Create `.claude/agents/scripts.md`, matching the other agent files (frontmatter `name`, `description`, `tools`; sections *Your scope*, *Stack*, *Commands*, *Conventions*), with the description and tools from the shared contract.

- **Your scope:** the ten top-level `scripts/*.sh` and `test/scripts/`. The "path decides the owner" rule and the coupled-script cases (`test_image.sh` ← `dev`, `test_cli_e2e.sh` / `bundle_cli.sh` ← `cli`, `release.sh` ← `automation` design). Do NOT touch: `scripts/ci/`, `.circleci/`, `Makefile`, `VERSION`, `DOCKERHUB_DESCRIPTION.md`, `test/bash32/`, `build/`, `Dockerfile`, `source/`, `cli/`, other `test/` folders, `docs/` and root-level files; report needed Makefile / CI changes to `automation`.
- **Stack:** Bash (`set -euo pipefail`), `shellcheck` (`SHELLCHECK_IMAGE`), bats on `BATS_IMAGE`, docker for scripts that build or run images.
- **Commands:** `make lint`, `make test`.
- **Conventions:** make is the only entry point (scripts are called through make targets); a Makefile recipe longer than one line moves to `scripts/*.sh`; usage header comment at the top of each script; scripts `cd` to the repo root via `BASH_SOURCE`; inputs validated up front with a `<name>: ...` error prefix; external commands (`gh`, …) stubbable in bats (`test/scripts/helpers/`); `check_guides_links.sh` runs on bash 3.2 (macOS).

## Files to Change

- `.claude/agents/scripts.md` — new.
