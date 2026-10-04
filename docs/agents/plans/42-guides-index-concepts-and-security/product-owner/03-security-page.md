# Write security.md
Create `docs/guides/vault/security.md` per `guides-pages.md` → `security.md`, from the README
`## Security` and `## Supported runtimes and platforms` sections:

- First line: one-line purpose and a relative link back to `../vault.md`.
- `--privileged` risks: host escape, all host devices, seccomp/AppArmor disabled, refused by
  most managed platforms.
- Sysbox (recommended, `--runtime=sysbox-runc`): own user namespace, root inside is not root
  on the host; link to Sysbox with an absolute URL.
- Root inside the container (the inner daemon needs it).
- Never expose the inner Docker socket: Vault starts `dockerd` with a unix `--host` only; no
  TCP listener, never publish 2375 / 2376.
- Do not mount the host's `docker.sock`.
- Secrets: keep env files out of git, never bake secrets into a derived image; details in
  `vault/configuration.md` (inline code, not linked).
- Supported / unsupported runtimes and platforms (Sysbox, `--privileged`; rootless Docker,
  `--cap-add`, host socket unsupported; managed platforms) and architectures
  (`linux/amd64`, `linux/arm64`).

## Files to Change
- `docs/guides/vault/security.md` — new page.
- `docs/guides/vault.md` — page index row (if not already added in step 01).
