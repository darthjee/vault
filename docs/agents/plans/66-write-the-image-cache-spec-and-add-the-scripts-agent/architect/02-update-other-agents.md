# Shrink automation and update the other agents

- `.claude/agents/automation.md` — *Your scope*: replace `scripts/` with `scripts/ci/*` and drop `test/scripts/`; add that it owns the release / buildx design implemented by `scripts/release.sh` (file owned by `scripts`) and delegates changes to top-level `scripts/*.sh` to `scripts`. Add `scripts/*.sh` and `test/scripts/` to its *Do NOT touch* line.
- `.claude/agents/dev.md` — *Do NOT touch*: `scripts/` and `test/scripts/` stay listed; the follow-up sentence reports Makefile / CI changes to `automation` and script changes (e.g. `test_image.sh`) to `scripts`.
- `.claude/agents/cli.md` — ownership line: `scripts/`, `test/scripts/` → `scripts`; the rest stays with `automation`. Bundling rule: `scripts/bundle_cli.sh` (owned by `scripts`).
- `.claude/agents/product-owner.md` — check only: `scripts/` is already in *Do NOT touch*; its "Assign each issue / plan step" list gains `scripts`.

## Files to Change

- `.claude/agents/automation.md`
- `.claude/agents/dev.md`
- `.claude/agents/cli.md`
- `.claude/agents/product-owner.md`
