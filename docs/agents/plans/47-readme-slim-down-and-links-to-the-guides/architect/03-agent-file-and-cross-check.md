# Fix product-owner.md and cross-check
- In `.claude/agents/product-owner.md` (around line 19), drop "(it does not exist yet; #42
  creates it)" from the `docs/guides/` ownership line.
- Cross-check after the other agents finish:
  `grep -rn 'README' --include='*.md' --include='*.sh' --include='*.bats' .` (excluding
  `docs/agents/specs/`, `issues/`, `plans/`) shows no link to a removed README anchor and no
  `"Supported runtimes" in the README`. `DOCKERHUB_DESCRIPTION.md` uses absolute guide URLs.
  `make lint`, `make test` and `make test-docs` pass.

## Files to Change
- `.claude/agents/product-owner.md`: drop the stale remark.
