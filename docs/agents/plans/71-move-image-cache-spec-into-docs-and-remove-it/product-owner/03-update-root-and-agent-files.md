# Point AGENTS.md and the agent files at release.md
Add `release.md` to the documentation indexes and replace every reference to the spec. These files are in the `architect` scope; `product-owner` provides the wording (see the plan's Notes).

- `AGENTS.md`:
  - `## Documentation` table: add a row `| [Release](docs/agents/release.md) | Image build and release: layer order, reproducible layers, builder, registry cache, cache-bust knob. |` after *Flow*.
  - `### Release (CircleCI)`: in the `build-and-release` bullet, add that it imports and exports the `darthjee/vault:buildcache` registry cache, and add one line: "Image build rules (layer order, reproducibility, cache): see `[Release](docs/agents/release.md)`."
- `.claude/agents/architect.md`: same row in its documentation table (`../../docs/agents/release.md`).
- `.claude/agents/product-owner.md`: add `release.md` to the owned files list (`architecture.md`, `flow.md`, ... line).
- `.claude/agents/scripts.md`: replace "as fixed by the spec" with "as documented in `docs/agents/release.md`".
- `.claude/agents/automation.md`: in the release / buildx design paragraph, add "documented in `docs/agents/release.md`"; in *Conventions*, add a bullet: keep the cache and reproducibility rules of `docs/agents/release.md` (PR builds never export the cache).
- `.claude/agents/dev.md`: *Conventions* bullet: keep the `Dockerfile` ordered from least to most frequently changing, `COPY build/vault` last, and keep it reproducible (see `docs/agents/release.md`).

## Files to Change
- `AGENTS.md` — documentation row, release section pointer.
- `.claude/agents/architect.md` — documentation row.
- `.claude/agents/product-owner.md` — owned files.
- `.claude/agents/scripts.md` — replace the spec reference.
- `.claude/agents/automation.md` — link the release design and cache rules.
- `.claude/agents/dev.md` — layer-order convention.
