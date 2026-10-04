# Contributing

## Commit Guidelines

- **Atomic and Unitary:** Each commit must represent a single logical change.
  *Example:*
  - Good: `Add dockerd_wait function with timeout`
  - Bad: `Add dockerd_wait and refactor compose argument handling`
- **No Unrelated Changes:** Do not mix unrelated changes in the same commit.
- **Separate Refactoring:** Whenever possible, separate refactoring commits from new feature or bugfix commits.

## Pull Requests

- **Descriptive Summary:** Every PR must include a clear and descriptive summary of its purpose and changes.
- **PR Description Files:** If a description cannot be provided directly in the PR, generate a file with the PR description (e.g., `docs/agents/issues/<pr_number>_description.md`), but do not commit this file.

## Definition of Done for PRs

A PR is considered complete when:

- The stated objective has been achieved.
- All tests are passing (bats unit tests and the image smoke test).
- `shellcheck` passes without errors.
- Test coverage of `source/lib/` functions is as high as reasonably possible.
- Code is not overly complex:
  - Each function has a clear, focused responsibility.
  - If a function is growing, extract parts into smaller helper functions.
  - *Example:*

    ```bash
    # Good: each function does one thing
    dockerd_start() { ... }
    dockerd_wait() { ... }

    # Bad: one function does everything
    boot() {
      start_dockerd
      wait_for_it
      load_images
      run_compose
    }
    ```

  - This requirement applies primarily to source code. For tests, refactor only if there is excessive duplication.

### CI Checks

Before a PR is considered complete, all CI checks relevant to the modified parts of the project must pass locally.

| Modified paths | Local commands |
| --- | --- |
| `Dockerfile`, `source/`, `test/` | `make lint`, `make test`, `make test-image`, `make test-cli-e2e` |
| `cli/`, `install.sh` | `make lint`, `make test`, `make test-cli-e2e` |
| `scripts/`, `Makefile` | `make lint` |
| `.circleci/` | `circleci config validate` (if the CLI is installed) |

If a new folder is added, its corresponding test and check jobs must be included before merging changes to that folder.

This same process must be followed when **planning how to resolve an issue**: include a final step in the plan that identifies the affected folders and lists the CI commands to run before opening a PR.

## Code Organization

### File Responsibility: Libraries vs Scripts

Every file under `source/lib/` must be a **library** — it only defines functions. Sourcing it must not execute logic, read the environment or produce side effects.

The only exceptions are **entrypoints / scripts**:

| Application | Entrypoint |
| --- | --- |
| Image (`source/`) | `source/bin/entrypoint.sh` |
| Repo tooling | `scripts/*.sh`, `scripts/ci/*.sh` |

*Example:*

```bash
# Good: library — only defines functions
# source/lib/images.sh
images_load_dir() {
  local dir="$1"
  ...
}

# Bad: library that runs code when sourced
# source/lib/images.sh
for tar in /vault/images/*.tar; do docker load -i "$tar"; done
```

Test files are exempt from this rule and may source libraries and execute setup code freely.

### Naming

- Files use `snake_case.sh`.
- Library functions are prefixed with their file's module name: `dockerd_start` in `dockerd.sh`, `compose_run` in `compose.sh`.
- Private helpers are prefixed with `_` (e.g. `_compose_build_args`).
- Test files mirror the library: `source/lib/compose.sh` → `test/lib/compose.bats`.

### Function Order: Public Before Private

Within a file, **public functions must be declared before private (`_`-prefixed) helpers**.

```bash
# Good
compose_run() { _compose_build_args "$@"; ... }
compose_down() { ... }
_compose_build_args() { ... }

# Bad
_compose_build_args() { ... }
compose_run() { ... }
```

### Bash Style

- Scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Always quote variable expansions (`"$var"`, `"${arr[@]}"`).
- Use `local` for every function variable.
- Use arrays for argument lists; never build commands as strings.
- Everything must pass `shellcheck`.

## Dependency Injection

Library functions must receive their inputs (paths, timeouts, argument lists) as **arguments**. A function must never read environment variables or hardcode paths on its own.

**The entrypoint is the only place that reads the environment** (`COMPOSE_UP_ARGS`, `VAULT_DOCKERD_TIMEOUT`, ...). It then passes values down to the functions.

This makes every function independently testable: tests call it with the values they need.

```bash
# Good: function receives its input
dockerd_wait() {
  local timeout="$1"
  ...
}
# In entrypoint.sh:
dockerd_wait "${VAULT_DOCKERD_TIMEOUT:-30}"

# Bad: function reads the environment itself
dockerd_wait() {
  local timeout="${VAULT_DOCKERD_TIMEOUT:-30}"  # ❌
  ...
}
```

## Refactoring Guidelines

When refactoring, aim to:

- **Reduce Code Duplication:** move repeated test setup into bats `setup()` functions or shared helpers under `test/helpers/`.
- **Keep commands mockable:** wrap external commands (`docker`, `dockerd`) so tests can stub them with functions.
