# Slim down the README
Rewrite `README.md` per [guides-readme.md](../../../specs/guides-readme.md#what-the-readme-keeps):

- Keep the title, badges, `**Current Version:** 0.0.1` (unchanged), the overview paragraphs, the
  port-flow diagram and the Docker Hub line.
- Add `## Quick start` with one `docker run` (Sysbox form: `--runtime=sysbox-runc`,
  `-v "$PWD/my-stack:/vault"`, `-v vault-data:/var/lib/docker`, `-p 8080:80`, `darthjee/vault`)
  and one `vault up` (with a one-line CLI install pointer to `docs/guides/vault/cli.md`). Say
  that the examples use the published `darthjee/vault` image.
- Add `## Documentation` (or similar) linking to `docs/guides/vault.md` for detailed usage, and
  saying that the guides can be copied into other repos.
- Replace `## Security` with a short summary: running an inner dockerd needs privileges; Sysbox
  (`--runtime=sysbox-runc`) is preferred and `--privileged` is the dangerous fallback; rootless
  Docker, `--cap-add` and mounting the host `docker.sock` are unsupported; the inner socket is
  never exposed over TCP. Then link to `docs/guides/vault/security.md` for the details.
- Delete `## CLI` (and every subsection), `## Usage` (and every subsection),
  `## Environment variables`, `## Behaviour` and `## Supported runtimes and platforms`.
- Keep `## Development` and `## License` as they are.

## Files to Change
- `README.md`: slimmed content.
