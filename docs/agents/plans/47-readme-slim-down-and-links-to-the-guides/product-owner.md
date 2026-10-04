# Product-owner Plan: README slim-down and links to the guides

Main plan: [plan.md](plan.md)

## Shared contracts

- Links from `docs/agents/*` to the guides are relative (`../guides/vault.md`,
  `../guides/vault/cli.md`, `../guides/vault/security.md`, ...). `make test-docs` does not check
  `docs/agents/`, so verify them by hand.
- Removed README anchors (see [plan.md](plan.md#shared-contracts)): nothing in `docs/agents/`
  may link to them afterwards. `../../README.md#security` still resolves, but prefer the guide.
- The CLI rootless hint becomes `vault: hint: see Security in the README` (done by `cli`).
- Do not touch `docs/agents/specs/` (#48 removes it).

## Implementation Steps

### Step 1 — Update `docs/agents/`
- `architecture.md`:
  - Around line 70, "user-facing behaviour: README `## CLI`" becomes a link to
    `../guides/vault/cli.md`.
  - Around lines 175 and 180, the "README Security section" links point at
    `../guides/vault/security.md`.
  - Grep the rest of `docs/agents/*.md` (excluding `specs/`, `issues/`, `plans/`) for other
    references to removed README sections, and for quotes of the old rootless hint.
- `folder-structure.md`: rewrite the `docs/guides/` row now that the tree is complete. Drop
  "#42 fills in the rest" and list the pages (`vault.md` index plus `vault/*.md`). Cover the
  portability rule (copied as a whole tree; relative links stay inside it; everything else uses
  absolute URLs), the `**Vault version:**` line (kept in sync by `bump-version` /
  `check-version-tag`) and `make test-docs`. Point the `README.md` row's description at the
  slimmed role (overview and quick start; detailed usage in `docs/guides/`).
- `contributing.md`: add a rule that a user-visible behaviour change (image, entrypoint, CLI,
  env vars) also updates the matching page in `docs/guides/` in the same PR, and that the
  README only changes when its overview or quick start does.

### Step 2 — Fix the tag clash in `base-image.md`
In `docs/guides/vault/base-image.md` → "Offline preload", the inner app image is saved as
`my-app`, and the baked image is later built with `docker build -t my-app .` (around line 79),
which overwrites it. Tag the inner app image `my-app:1.0` in the `docker save` line (and
wherever the section or its compose example refers to the inner image), as `examples.md` does.
Also check whether `cli.md` or `troubleshooting.md` quote the old rootless hint; if they do,
update them to `see Security in the README`.

## Files to Change
- `docs/agents/architecture.md`: links to the guides instead of README sections.
- `docs/agents/folder-structure.md`: the `docs/guides/` row and the `README.md` row.
- `docs/agents/contributing.md`: the "behaviour change updates the guides" rule.
- `docs/guides/vault/base-image.md`: inner image tag.

## CI Checks
- `docs/guides/`: `make test-docs` (CI job: `build-and-test`)

## Notes
- The guides' version line and portability rules are unchanged here.
