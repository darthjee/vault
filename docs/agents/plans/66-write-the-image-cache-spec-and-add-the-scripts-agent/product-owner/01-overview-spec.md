# Write the overview spec

Create `docs/agents/specs/image-cache-overview.md` — **final** depth. It is the entry point every sub-issue of epic #65 reads. Sections:

- **Goal** — reuse unchanged layers of `darthjee/vault` in CI builds and in what is pushed to / pulled from Docker Hub.
- **Current state** — no cache on fresh `machine` executors; rebuilt layers get new timestamps, so new digests; `COPY build/vault` (changes every release) before rarely-changing layers; a plain `docker pull` does not feed the `buildx` `docker-container` builder.
- **Decision** — D (reorder, #68) + C (reproducible layers, #69) + A (registry cache, #70).
- **Rejected alternatives** — inline cache from `:latest` (weak for multi-arch, `mode=min`), CircleCI Docker Layer Caching (paid, no Docker Hub / pull benefit), shared builder image in another project (cross-repo releases and pin bumps for every build fix).
- **Shared contracts** — cache tag and who reads / writes it, `SOURCE_DATE_EPOCH` source, the `scripts` agent (name + one-line scope, details in `image-cache-agents.md`), `Dockerfile` order rule (least to most frequently changing, `COPY build/vault` last among content layers).
- **Sequencing** — #66 → #68 → #69 → #70 → #71.
- **Backward compatibility** — no change to image contents or runtime behaviour; new `:buildcache` tag noted in `DOCKERHUB_DESCRIPTION.md`; digests change once with the reorder, then stay stable for unchanged layers.
- **Security** — stale `apk` packages: a cache-bust knob is required (form decided in #69); no cache poisoning: PR builds never write the cache, only the `docker-hub` context can push it.
- **Runtime privileges** — none change.
- **Files** — index table linking the four feature files, each with the sub-issue that reads it and its depth (final / goals + acceptance + open decisions).
- **Spec rules** — non-final files carry an *Open decisions* section; the owning sub-issue closes it and updates the file in its own PR.

## Files to Change

- `docs/agents/specs/image-cache-overview.md` — new.
