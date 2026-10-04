# Write the guides spec

Create the four `docs/agents/specs/guides-*.md` files. Use the former CLI spec (#21, commit
`b8b073f`, `cli-overview.md`) as the shape model: short sections, tables for mappings.

**`guides-overview.md`** (index)

- Title `# Guides Spec: Overview`, a status paragraph linking to `../specs.md` (working
  document for epic #39, removed by #48) and a table of the other three files.
- Goals (from #39 Description/Problem) and out of scope (no shipping in the image /
  `install.sh` / release, no upgrading guide, no behaviour change, no translations).
- Paths: `docs/guides/vault.md` + `docs/guides/vault/*.md`; the copy unit is the whole
  `docs/guides/` tree.
- Agent ownership: `product-owner` owns `docs/guides/`; `automation` owns the link-check
  script, Make target, CI wiring, version-line handling and `DOCKERHUB_DESCRIPTION.md` links;
  `architect` owns the README and `AGENTS.md`.
- Backward compatibility (from #39).
- **Sub-issue map:** #41 → `guides-portability.md` (version line, link check); #42 → index,
  `concepts.md`, `security.md`; #43 → `docker-run.md`, `base-image.md`; #44 → `cli.md`;
  #45 → `configuration.md`, `operations.md`, `troubleshooting.md`; #46 → `examples.md`,
  `agents-snippet.md`; #47 → `guides-readme.md`; #48 → spec removal. Include the dependency
  order from #39's Split table (4/5/6 parallel after 3).
- Open points: anything the spec leaves to the implementing sub-issue.

**`guides-pages.md`**

- Audience and style: humans and AI agents in consumer repos; plain, task-oriented Markdown;
  each page starts with a one-line purpose and a link back to `../vault.md`.
- One section per page: `vault.md` (what Vault is, when to use it, choosing a path — image vs.
  CLI, image as is vs. base image — and the page index) and each `vault/*.md` page with the
  topics from #39's Scope table, checked against the current README sections and `AGENTS.md`.
- **Ports:** the CLI default `-p 3000:80` vs. the `docker run` examples' `-p 8080:80`. Decide
  the presentation: each page states which mapping it uses, `concepts.md` explains the port
  flow (host → Vault `80` → inner service), and `examples.md` shows both variants with their
  own mapping.
- Image tags: `darthjee/vault:<version>` placeholder; `darthjee/vault` / `:latest` only in
  quick starts, said explicitly.

**`guides-portability.md`**

- Portability rules (from #39): relative links only between guide pages, resolving inside
  `docs/guides/` (anchors included); absolute `https://` for anything outside; no links into
  the consumer repo; no assets; `vault.md` top block says copy the whole tree, where the
  originals live (absolute GitHub URL) and which version the guides match.
- **Version line:** exact format `**Vault version:** X.Y.Z` on its own line near the top of
  `docs/guides/vault.md`; updated by `scripts/bump_version.sh`, validated by
  `scripts/check_tag_version.sh` / `check-version-tag`, like the README `**Current Version:**`
  line (#41).
- **Link check contract (#41):** a script under `scripts/` (name chosen by #41, e.g.
  `scripts/check_guides_links.sh`) and `make test-docs`, run in the CircleCI PR pipeline
  (`build-and-test`, alongside `make lint` / `make test`). It fails on: a relative link that
  leaves `docs/guides/`; a relative link to a missing file or anchor; a link that is neither
  relative-inside nor absolute `https://`. Define the anchor slug rule (GitHub-style) and that
  code blocks are ignored.
- Edge cases: copying the tree to another location; anchors surviving heading renames.

**`guides-readme.md`**

- Map each current README section to its fate: `## CLI` (and subsections) → `vault/cli.md`;
  `## Usage` → `docker-run.md` / `base-image.md` / `concepts.md` / `operations.md` as fits;
  `## Environment variables` → `configuration.md`; `## Behaviour` → `concepts.md` /
  `operations.md` / `troubleshooting.md`; `## Supported runtimes and platforms` and
  `## Security` → `security.md`.
- What the README keeps: title/overview, a quick start, a link to `docs/guides/vault.md`, the
  `**Current Version:**` line, a short Security summary (required by `AGENTS.md` → Privileges;
  note that #47 must keep or adjust that rule), `## Development`, `## License`.
- Links to update in #47: `DOCKERHUB_DESCRIPTION.md` (`#cli`, `#security` anchors),
  `AGENTS.md` ("user docs: the README `## CLI` section"), `docs/agents/*`.

## Files to Change

- `docs/agents/specs/guides-overview.md` — new.
- `docs/agents/specs/guides-pages.md` — new.
- `docs/agents/specs/guides-portability.md` — new.
- `docs/agents/specs/guides-readme.md` — new.
