# Link the pages from vault.md and update the spec
In `docs/guides/vault.md`:

- "Choosing a path" tables: replace `` `vault/docker-run.md` (not written yet) `` (both rows)
  and `` `vault/base-image.md` (not written yet) `` with relative links
  ([docker-run.md](vault/docker-run.md), [base-image.md](vault/base-image.md)). Leave the
  `cli.md` row as is.
- "Page index": add one row per new page, after `security.md`.

In `docs/agents/specs/guides-pages.md` → `## docker-run.md`, add the agreed bullet: a short
stop-timeout example (`docker stop -t`, `--stop-timeout`) pointing to `operations.md` for the
full shutdown sequence; also mention `--env-file` next to `-e`.

Run `make test-docs` and fix any reported link.

## Files to Change
- `docs/guides/vault.md` — link both pages; add page-index rows.
- `docs/agents/specs/guides-pages.md` — record the stop-timeout and `--env-file` bullets for
  `docker-run.md`.
