# Write base-image.md
Create `docs/guides/vault/base-image.md`: how to ship a compose stack as its own image built
on Vault.

Header: `# Using Vault as a base image`, a one-line purpose, and
"Back to the [Vault guides index](../vault.md)."

Sections:

- **Dockerfile:** `FROM darthjee/vault:<version>` + `COPY . /vault`; a `.dockerignore`
  hint so env files and secrets are not copied.
- **Offline preload:** every `/vault/images/*.tar` is `docker load`ed before compose starts;
  create them with `docker save -o images/my-app.tar my-app`; a missing `/vault/images` is
  skipped; prevent pulls with `COMPOSE_UP_ARGS="--pull never"` (e.g. `ENV` in the Dockerfile
  or `-e`) or `pull_policy:` in the compose file. Verify against `source/lib/images.sh`.
- **Running the baked image:** `docker build -t my-app .`, then `docker run` with Sysbox (and
  the `--privileged` fallback, linking [security.md](security.md)), the data volume and
  `-p 8080:80` (say this page uses it); link [docker-run.md](docker-run.md) for the flags.
  With the CLI: `vault up --image my-app -p 8080:80` — nothing is mounted on `/vault`, the
  instance is named after the image; details in `cli.md` (inline code, not written yet).
- **Secrets:** never bake secrets into the derived image; pass them at run time (`-e`,
  `--env-file`); details in `configuration.md` (inline code, not written yet); link
  [security.md](security.md).

## Files to Change
- `docs/guides/vault/base-image.md` — new page.
