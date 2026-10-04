# Write configuration.md
Create `docs/guides/vault/configuration.md`: how to configure a Vault stack and keep secrets safe.

- Header: one-line purpose + link to `../vault.md`.
- Env var table (from README `## Environment variables`): `COMPOSE_FILE`, `COMPOSE_PROJECT_NAME`,
  `COMPOSE_UP_ARGS` (split on whitespace, **no quoting support**; examples
  `--abort-on-container-exit`, `--pull never`), `VAULT_DOCKERD_TIMEOUT` (positive integer, default
  `30`; invalid value → startup error, link to `troubleshooting.md`). Other `COMPOSE_*` variables
  pass through to compose.
- Multiple compose files: `COMPOSE_FILE=compose.yml:compose.prod.yml` (`:`-separated, paths
  relative to `/vault`).
- Passing variables: `docker run -e` / `--env-file` (`-p 8080:80`, said on the page) and the CLI
  (`.vault.env`, options; link to `cli.md` for precedence rather than restating it).
- **Secrets handling:** keep `.vault.env` and env files out of git (`.gitignore` example); never
  bake secrets into a derived image (`COPY . /vault` copies everything — use `.dockerignore`;
  pass secrets at run time); the CLI prints env keys only, never values.

## Files to Change
- `docs/guides/vault/configuration.md` — new page.
