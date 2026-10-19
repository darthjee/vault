# Delete the spec and its row
Remove the image-cache spec now that its content lives in `release.md`.

- `git rm` the five `docs/agents/specs/image-cache-*.md` files; keep `docs/agents/specs/.gitkeep`.
- `docs/agents/specs.md` → *Active specs*: delete the `image-cache-` row; keep the intro sentence and the table header (`| Prefix | Epic | Removed by |` plus the separator) with no rows, for future specs.
- Check no reference is left: `grep -rn "image-cache" --exclude-dir=.git .` only matches files under `docs/agents/issues/` and `docs/agents/plans/`.
- Run `make test-docs`.

## Files to Change
- `docs/agents/specs/image-cache-overview.md`, `image-cache-agents.md`, `image-cache-dockerfile.md`, `image-cache-reproducible.md`, `image-cache-registry-cache.md` — deleted.
- `docs/agents/specs.md` — remove the *Active specs* row.
