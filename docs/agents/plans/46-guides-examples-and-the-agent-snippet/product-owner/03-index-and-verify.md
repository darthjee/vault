# Index both pages in vault.md and verify
Add two rows to the `## Page index` table of `docs/guides/vault.md`, after
`troubleshooting.md`:

| Page | Contents |
|------|----------|
| `[examples.md](vault/examples.md)` | Worked setups (app + Postgres, app + Redis, multiple compose files, baked image with offline preload), each with `docker run` and CLI variants. |
| `[agents-snippet.md](vault/agents-snippet.md)` | A block to paste into your repo's `AGENTS.md` pointing at these guides, with the key rules. |

No other change to `vault.md` (no extra pointer under "Choosing a path", per the issue).

Then verify:
- `make test-docs` passes (all relative links and anchors in the new pages resolve).
- Every port mapping shown on `examples.md` says which mapping it uses.
- No reference-style links, images, `http://` links or links outside `docs/guides/`.

## Files to Change
- `docs/guides/vault.md` — two new page-index rows.
