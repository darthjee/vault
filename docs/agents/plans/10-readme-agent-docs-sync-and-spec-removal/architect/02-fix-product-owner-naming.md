# Fix issue naming in product-owner agent

`.claude/agents/product-owner.md` documents `issues/` as `<issue_id>_<issue_name>.md` and `plans/` as `<issue_id>_<topic>/plan.md`. The tooling writes `<issue_id>-<slug>.md` and `<issue_id>-<slug>/`. Update both lines. Then grep `.claude/agents/` and `docs/agents/*.md` for any other `<issue_id>_` wording and fix it too.

## Files to Change
- `.claude/agents/product-owner.md` — issue and plan naming conventions.
