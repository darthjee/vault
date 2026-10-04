# Write concepts.md
Create `docs/guides/vault/concepts.md` per `guides-pages.md` → `concepts.md`:

- First line: one-line purpose and a relative link back to `../vault.md`.
- Docker-in-Docker: the entrypoint starts an inner `dockerd`; the stack runs under it.
- `/vault` as the working directory; relative paths resolve against it.
- Port flow: host → Vault `80` → inner service, with the README `### Ports` compose and
  `docker run` example (`-p 8080:80`, said on the page); `EXPOSE 80` is a convention only;
  internal services publish no ports; no built-in reverse proxy.
- Bind mounts in the inner compose file refer to the **Vault container's** filesystem, not
  the host's (README `### Bind mounts`).
- Persistence model: `VOLUME /var/lib/docker`; a named volume keeps the image cache and inner
  named volumes; without it images are pulled again and inner data is lost. Data-volume
  operations (sharing, backups) belong to `vault/operations.md` (inline code, not linked).
- Startup sequence in short: pre-checks, `dockerd`, offline preload (`/vault/images/*.tar`),
  `docker compose`, exit with compose's exit code.

## Files to Change
- `docs/guides/vault/concepts.md` — new page.
- `docs/guides/vault.md` — page index row (if not already added in step 01).
