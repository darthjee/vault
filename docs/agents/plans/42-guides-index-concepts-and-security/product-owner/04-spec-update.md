# Record the unwritten-page rule in the spec
Per the spec hub's deviation rule, record the decision from #42 in the spec in the same PR:
in `guides-overview.md` → Sub-issue map, next to "Each page sub-issue also adds its page to the
page index of `vault.md`", add that pages not written yet are named in inline code (not
linked) so the link check passes, and that the sub-issue that writes a page turns every such
mention into a relative link. Optionally mirror this in `guides-pages.md` → `vault.md`
("Page index: one line per page, filled as each page lands").

Then run `make test-docs` and fix any reported link.

## Files to Change
- `docs/agents/specs/guides-overview.md` — add the rule.
- `docs/agents/specs/guides-pages.md` — optional one-line mirror.
