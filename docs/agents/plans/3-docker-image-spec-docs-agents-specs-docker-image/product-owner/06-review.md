# Consistency review and checks
- Check that every decision in issue #3's Solution section appears in exactly one spec file, and that `overview.md`'s sub-issue map points to the right sections.
- Check that every relative link in the spec and in `AGENTS.md` resolves.
- Check that the diff touches only `docs/agents/specs/docker-image/*` and `AGENTS.md`.
- Run `.claude/scripts/check_product-owner.sh` (no-op). There is no other CI for docs.

## Files to Change
- None; this step only verifies.
