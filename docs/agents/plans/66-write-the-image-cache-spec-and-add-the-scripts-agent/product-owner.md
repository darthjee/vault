# Product Owner Plan: Write the image-cache spec and add the scripts agent

Main plan: [plan.md](plan.md)

## Shared contracts

- Write the **Scripts agent** contract from [plan.md](plan.md#shared-contracts) verbatim (name, owned paths, the "path decides the owner" rule, what `automation` keeps) into `image-cache-agents.md`; `architect` implements the same text in `.claude/` and `AGENTS.md`.
- Fix the **Spec contracts** from [plan.md](plan.md#shared-contracts) in `image-cache-overview.md`.

## Steps

- [01 — Write the overview spec](product-owner/01-overview-spec.md)
- [02 — Write the feature spec files](product-owner/02-feature-spec-files.md)
- [03 — Register the spec and update folder-structure.md](product-owner/03-hub-and-folder-structure.md)

## CI Checks

- `make lint`, `make test` (CI job: `build-and-test`) — must stay green (no code changes).
- Manual: `scripts/check_guides_links.sh docs/agents/specs` must print `test-docs: OK (5 file(s))`; report the output in the PR.

## Notes

- Spec files link **only to each other**; repo paths (`Dockerfile`, `scripts/release.sh`, …) and issue numbers are inline code / plain text, never relative links leaving `docs/agents/specs/` — otherwise the manual link check fails.
- Follow the shape of the former CLI spec (#21, removed by #51): flat files, `<topic>-overview.md` as index.
- Out of scope: adding `docs/agents/` to `make test-docs` (#72).
