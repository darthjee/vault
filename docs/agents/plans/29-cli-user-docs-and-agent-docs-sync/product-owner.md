# Product Owner Plan: CLI user docs and agent docs sync

Main plan: [plan.md](plan.md)

## Shared contracts

- Produce the README `## CLI` section (anchor `#cli`) that `DOCKERHUB_DESCRIPTION.md` links to.
- Use the exact install one-liner, install defaults, quick-start commands and platform line
  from [plan.md → Shared contracts](plan.md#shared-contracts).

## Steps

- [01 — README CLI section](product-owner/01-readme-cli-section.md)
- [02 — AGENTS.md](product-owner/02-agents-md.md)
- [03 — folder-structure.md](product-owner/03-folder-structure.md)
- [04 — architecture.md](product-owner/04-architecture.md)
- [05 — flow.md CLI flow](product-owner/05-flow-cli.md)

## Notes

- Facts come from the code first (`cli/`, `install.sh`, `source/bin/install.sh`, `Makefile`,
  `scripts/`, `.circleci/config.yml`), then from `docs/agents/specs/cli-*.md`. Where they
  differ, the code wins: describe what was built.
- Do not edit or delete `docs/agents/specs/`, and keep the "specs override these docs" notes
  in `AGENTS.md` and `folder-structure.md`: #30 removes both. The spec's open points are not
  updated.
- Do not shorten the README for epic #39: it moves sections into `docs/guides/` later.
- No tests (documentation only). `make lint` / `make test` are unaffected.
