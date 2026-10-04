# Options, configuration, guardrails and baked images
Add the configuration sections:

- **Options:** ports (default `3000:80`), volumes, env, env files, stop timeout, `--image`;
  take the flag list and defaults from `cli/lib/args.sh` and `vault help`.
- **`.vaultrc`** (own heading, anchor `vaultrc`): keys, precedence (flags > `.vaultrc` >
  defaults), relative paths resolved against the `.vaultrc` location (check
  `cli/lib/config.sh`).
- **`.vault.env`:** what it holds and that it stays out of git; full secrets handling is in
  `configuration.md` (not written yet).
- **Guardrails:** each check in `cli/lib/guardrails.sh` and what the user sees when it trips.
- **Baked images:** `vault up --image <image>` without a `[dir]`, naming after the image; link
  `base-image.md`.
- **Docker Desktop:** file-sharing paths that must be shared for bind mounts on macOS.

## Files to Change
- `docs/guides/vault/cli.md` — Options, `.vaultrc`, `.vault.env`, Guardrails, Baked images,
  Docker Desktop sections.
