# Issue: Write the image-cache spec and add the scripts agent

## Description

First sub-issue of epic #65 (reuse unchanged image layers across builds and releases). It writes the epic's spec under `docs/agents/specs/image-cache-*.md` and adds the `scripts` specialist agent the spec names (merged from #67, following the #21 precedent: CLI spec + `cli` agent in one PR).

## Problem

Unchanged layers of the `darthjee/vault` image are not reused today:

- CI builds on fresh `machine` executors with no cache.
- Rebuilt layers get new file timestamps (git checkout sets mtimes), so identical content yields new digests on Docker Hub and new downloads for users.
- `COPY build/vault` — which changes every release — sits before layers that rarely change.

The epic decided to combine three approaches:

- **D** — reorder the `Dockerfile` so frequently-changing layers come last (#68).
- **C** — reproducible layers: `SOURCE_DATE_EPOCH` + `rewrite-timestamp=true`, so unchanged content keeps the same digest (#69).
- **A** — a registry cache on a dedicated tag, `darthjee/vault:buildcache` (`mode=max`): every build imports it, only releases export it (#70).

Rejected alternatives (recorded in #65): inline cache from `:latest`, CircleCI Docker Layer Caching, a shared builder image in another project.

Before #68–#70 start, the shared contracts must be fixed in a spec so later sub-issues do not re-decide them, and the agent that will own the new / changed scripts must exist.

## Expected Behavior

- `docs/agents/specs/` holds the five `image-cache-*.md` files below, and `docs/agents/specs.md` lists the spec in its *Active specs* table (prefix `image-cache-`, epic #65, removed by #71).
- `.claude/agents/scripts.md` exists and the ownership of `scripts/` is split between `scripts` and `automation` everywhere it is documented, with no overlap.
- No script, `Dockerfile`, Makefile or CI behaviour changes.

## Solution

### Spec file layout

One file per feature (each feature maps to one sub-issue), plus an overview. All under `docs/agents/specs/`:

| File | Covers | Read by | Depth |
|---|---|---|---|
| `image-cache-overview.md` | Goal, the D + A + C decision, rejected alternatives, **shared contracts**, sequencing, backward compatibility, security, index of the other files | every sub-issue | **Final** |
| `image-cache-agents.md` | The `scripts` agent: scope, what `automation` keeps, docs to update | #66 (this issue) | **Final** — implemented here |
| `image-cache-dockerfile.md` | Target layer order, permissions that must not change | #68 | **Final** |
| `image-cache-reproducible.md` | `SOURCE_DATE_EPOCH` / `rewrite-timestamp`, `apk` layer, cache-bust knob, digest-comparison check | #69 | **Goals + acceptance + open decisions** |
| `image-cache-registry-cache.md` | Who imports / exports `:buildcache`, fallback on missing or unreachable cache, `DOCKERHUB_DESCRIPTION.md` note | #70 | **Goals + acceptance + contracts** |

Rules:

- Each feature file has its own **Edge cases** and **Acceptance criteria** sections, so a sub-issue only needs the overview plus its own file.
- Cross-cutting concerns (backward compatibility, cache poisoning) live only in the overview.
- Every non-final file has an **Open decisions** section; the owning sub-issue (#69, #70) closes them and updates the file in its own PR (the existing `docs/agents/specs.md` rule: a PR that deviates from a spec updates the spec).
- Spec files link only to each other; repo paths are written as inline code, not links.
- The clean-up sub-issue (#71) has no file; it is driven by `docs/agents/specs.md`.
- One spec issue, not several: the spec is small, and the overview must fix the contracts before any implementation.

### Shared contracts (overview)

- **Cache tag:** `darthjee/vault:buildcache`. `build-and-test` imports it anonymously (public repo, no credentials, no new context); `build-and-release` (context `docker-hub`) imports and exports it (`mode=max`). PR builds never write it.
- **`SOURCE_DATE_EPOCH`** = timestamp of the last commit (`git log -1 --format=%ct`).
- **Agent:** name `scripts`, scope as below.
- **`Dockerfile` layer order:** least to most frequently changing, `COPY build/vault` last among content layers.
- **Sequencing:** #66 → #68 → #69 → #70 → #71.

### Required content per feature file

- **Edge cases** — missing cache on the first build must not fail it; Docker Hub unreachable or rate-limited degrades to an uncached build; a `DOCKER_VERSION` bump invalidates every layer; multi-arch cache with `mode=max`.
- **Backward compatibility** (overview) — no change to image contents or runtime behaviour; the new `:buildcache` tag is noted in `DOCKERHUB_DESCRIPTION.md`; digests change once with the reorder.
- **Acceptance criteria** — two builds of the same commit produce identical layer digests; after a `cli/`-only change only the last layer differs; `make test-image` and `make test-cli-e2e` stay green.
- **Security** (overview) — stale `apk` packages need a cache-bust knob (open decision for #69); no cache poisoning from PRs.
- **Open decisions** in `image-cache-reproducible.md` — minimum buildx / BuildKit version, how the `apk` layer stays deterministic, the knob's form, whether the digest check runs in CI. In `image-cache-registry-cache.md` — exact `--cache-from` / `--cache-to` flags.

### Scripts agent

- Add `.claude/agents/scripts.md` — a `scripts` specialist owning `scripts/*.sh` (top level, not `scripts/ci/`) and their bats tests under `test/scripts/`. Same frontmatter (`name`, `description`, `tools`) and sections (*Your scope*, *Stack*, *Commands*, *Conventions*) as the other agents. Stack: Bash, `set -euo pipefail`, `shellcheck`, bats on `BATS_IMAGE`. Commands: `make lint`, `make test`. Conventions currently stated for scripts (a Makefile recipe longer than one line moves to `scripts/*.sh`; usage header comment at the top of each script).
- **The path decides the owner:** every top-level `scripts/*.sh` belongs to `scripts`, with no exceptions — including scripts coupled to another agent's domain:
  - `test_image.sh` (image assertions → `dev`), `test_cli_e2e.sh` and `bundle_cli.sh` (CLI behaviour / bundling rule → `cli`): the domain agent states what must be asserted or bundled and reports it; `scripts` implements it.
  - `release.sh`: `automation` owns the release design (platforms, tags, cache and reproducibility flags as fixed by the spec); `scripts` owns the file and implements that design.
- Shrink `.claude/agents/automation.md`: it keeps `.circleci/config.yml`, `Makefile`, `scripts/ci/*`, `VERSION`, `DOCKERHUB_DESCRIPTION.md`, `test/bash32/`, `build/` and the release / buildx design, and delegates changes to `scripts/*.sh` to `scripts`.
- Update every ownership reference to `scripts/` / `test/scripts/`:
  - `AGENTS.md` (agent table, ~line 238) — add the `scripts` row, shrink `automation`'s.
  - `.claude/agents/architect.md` (roster, ~line 25) — same.
  - `.claude/agents/dev.md` and `.claude/agents/cli.md` (*Do NOT touch* / ownership lines; `cli.md`'s bundling rule now says `scripts/bundle_cli.sh` is owned by `scripts`; `dev.md`'s "report it so `automation` can make it" also names `scripts` for script changes).
  - `.claude/agents/product-owner.md` (*Do NOT touch* list) — unchanged in effect, checked.
  - `docs/agents/folder-structure.md` (`test/scripts/` owner column, `scripts/` section).
- Out of scope: changing any script's behaviour.

### Responsible agents

- `product-owner` — the spec files and `docs/agents/specs.md`.
- `architect` — `.claude/agents/scripts.md`, `automation.md`, the other agent files and `AGENTS.md`; `docs/agents/folder-structure.md` ownership rows (with `product-owner`).

### Testing strategy

1. **Spec cross-links** — run `scripts/check_guides_links.sh docs/agents/specs` manually and report the result in the PR. The `docs/agents/specs.md` → spec row is checked by review.
2. **Agent file shape** — `scripts.md` matches the other agents' frontmatter and sections.
3. **Ownership** — every file under `scripts/` and `test/scripts/` is owned by exactly one agent (`scripts/*.sh` → `scripts`, `scripts/ci/*` → `automation`), checked by review against `ls scripts scripts/ci test/scripts`.
4. **Regression** — `make lint` and `make test` stay green.

Out of scope: adding `docs/agents/` to `make test-docs` in CI (#72).

## Benefits

- #68, #69 and #70 start from fixed contracts and do not re-decide them.
- Research-heavy details (BuildKit version, `apk` determinism) are decided where they are prototyped, not guessed up front.
- Script changes in the epic have a dedicated owner from the start.
