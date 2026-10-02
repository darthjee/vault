# Architect Plan: README, agent docs sync and spec removal

Main plan: [plan.md](plan.md)

## Shared contracts

- `README.md` must have a `## Security` heading (anchor `#security`). `DOCKERHUB_DESCRIPTION.md` and `architecture.md` link to it.
- `README.md` must keep the exact `**Current Version:** 0.1.0` line, which `scripts/check_tag_version.sh` and `scripts/bump_version.sh` read.
- Delete `docs/agents/specs/` only after product-owner's steps are done (step 04 runs last).
- Describe the flow, credentials, Makefile and naming convention exactly as listed in [plan.md → Shared contracts](plan.md#shared-contracts).

## Steps

- [01 — Update AGENTS.md](architect/01-update-agents-md.md)
- [02 — Fix issue naming in product-owner agent](architect/02-fix-product-owner-naming.md)
- [03 — Write README.md](architect/03-write-readme.md)
- [04 — Delete the spec and verify](architect/04-delete-spec.md)

## CI Checks

None. Only Markdown changes. Check that the version line is still intact with `make check-version-tag TAG=0.1.0`.

## Notes

- `DOCKERHUB_DESCRIPTION.md` (owned by `automation`) already matches. Only check that its `#security` link resolves once the README exists; do not edit it.
- Keep the README prose consistent with `DOCKERHUB_DESCRIPTION.md` (same diagram, same run examples).
