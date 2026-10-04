# Write agents-snippet.md
Create `docs/guides/vault/agents-snippet.md`.

Layout (decided in the issue): a short intro, then one fenced ```` ```markdown ```` block to
copy.

- Intro (outside the block): what the block is for, paste it into the consumer repo's
  `AGENTS.md` (or `CLAUDE.md`), and adjust the paths if the guides tree was copied somewhere
  other than `docs/guides/`. Mention the copy unit (the whole `docs/guides/` tree, see
  [../vault.md](../vault.md)).
- The block itself, a `## Vault` section kept short (~10–15 lines):
  - Pointer: "Vault usage is documented in `docs/guides/vault.md` and `docs/guides/vault/`;
    read them before changing how the stack runs" — paths written relative to the consumer
    repo root, with the "adjust the path" hint.
  - Key rules, one bullet each:
    - Privileges: Vault needs the Sysbox runtime (preferred) or `--privileged` (fallback);
      never `--cap-add` subsets, rootless Docker or the host's `docker.sock`.
    - `/vault`: the compose project lives at `/vault` (mounted or `COPY`'d); `docker compose`
      runs there.
    - Ports: host → Vault port (default `80`) → inner service via `ports: ["80:<app port>"]`;
      internal services publish nothing.
    - Bind mounts in the inner compose file refer to the Vault container's filesystem, not
      the host's; relative paths resolve against `/vault`.
    - Secrets: keep env files out of git and never bake secrets into images.
  - Each rule may name the guide page that covers it (as a plain path in the block, e.g.
    `docs/guides/vault/security.md`).
- Since the block is fenced, its paths are not checked by `make test-docs`; keep them
  matching the real file names. Links in the intro (outside the block) must be relative and
  pass the check.

## Files to Change
- `docs/guides/vault/agents-snippet.md` — new page.
