# Fill the index page
Extend `docs/guides/vault.md` per `guides-pages.md` → `vault.md`:

- Keep the existing title, top block (copy the whole tree, originals URL) and the single
  `**Vault version:** X.Y.Z` line exactly as they are (`check-version-tag` and
  `bump_version.sh` depend on it).
- **What Vault is:** a Docker-in-Docker image running a `docker compose` stack in one
  container that exposes one port; include the port-flow diagram from the README overview.
- **When to use it / when not:** ship an app and its dependencies as one image; not on managed
  platforms that refuse privileged containers (link to `vault/security.md`).
- **Choosing a path:** image directly (`vault/docker-run.md`) vs. the `vault` CLI
  (`vault/cli.md`); image as is (mount the project at `/vault`) vs. base image
  (`vault/base-image.md`). These pages don't exist yet: name them in inline code, no link.
- **Page index:** one line per existing page, linked: `vault/concepts.md`,
  `vault/security.md`. Later sub-issues add their own rows.

## Files to Change
- `docs/guides/vault.md` — add the sections above below the version line.
