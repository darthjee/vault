# Write docker-run.md
Create `docs/guides/vault/docker-run.md`: how to run a compose project with the published
image directly, without the CLI.

Header: `# Running the image with docker run`, a one-line purpose, and
"Back to the [Vault guides index](../vault.md)."

Sections:

- **Runtime:** Sysbox (`--runtime=sysbox-runc`) recommended; `--privileged` as the fallback,
  linking to [security.md](security.md) before using it. One complete example for each.
- **Mounting the project:** the compose project on `/vault` (`-v "$PWD/my-stack:/vault"`);
  link [concepts.md](concepts.md) for `/vault` and bind mounts.
- **The data volume:** `-v vault-data:/var/lib/docker`, what it keeps (link
  [concepts.md](concepts.md) for the persistence model), and never share one volume between two
  running containers.
- **Ports:** `-p 8080:80` (say this page uses it), host → Vault `80` → inner service; link
  [concepts.md](concepts.md) for the port flow.
- **Environment variables:** `-e KEY=value` and `--env-file <file>`; the full list lives in
  `configuration.md` (inline code, not written yet); keep env files out of git.
- **Compose arguments:** no arguments → `docker compose up ${COMPOSE_UP_ARGS}`; any arguments
  → `docker compose "$@"`; examples `config`, `ps`, `up --build`.
- **Stopping:** one short example (`docker run --stop-timeout 60 …` / `docker stop -t 60 …`)
  explaining that compose needs time to stop the inner stack; the full shutdown sequence lives
  in `operations.md` (inline code, not written yet).
- A pointer to the CLI alternative: `cli.md` (inline code, not written yet).

Verify every flag and behaviour against README `### Running`, `### Arguments` and
`source/bin/entrypoint.sh`.

## Files to Change
- `docs/guides/vault/docker-run.md` — new page.
