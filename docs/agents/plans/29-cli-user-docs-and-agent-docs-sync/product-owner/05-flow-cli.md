# flow.md CLI flow

Add a `## CLI flow` section to `docs/agents/flow.md` after the image flow (keep the existing
content; retitle the current overview "Image flow" only if it reads better):

1. **Resolution** (every command, `vault_resolve` in `cli/bin/vault`): parse options → read
   `.vaultrc` from `[dir]` (else `$PWD`) → merge (flags > `.vaultrc` > defaults) → instance
   name → `docker` on `PATH`.
2. **`up` / `run` only:** one `docker info` (daemon reachable, rootless refused, runtime
   selection), guardrails, `.vault.env` placement, container arguments (the ordered list from
   `cli-commands.md → Container arguments`).
3. **`up`:** instance state check (running → no-op; stopped → `docker rm` then run; missing →
   run), `docker run -d` (or foreground with `-f`), `vault-<name> started`; port / Sysbox
   failure hints.
4. **`run`:** refuses while `vault-<name>` runs; `docker run --rm [-i] [-t]` passing the
   compose args; exits with docker's code.
5. **`down` / `logs` / `status` / `compose`:** one `docker inspect` to tell running / stopped /
   missing / daemon unreachable; then `docker stop -t` + `docker rm` (volume kept),
   `docker logs`, the status report, or `docker exec [-i] [-t] … docker compose`.
6. **Install flow:** `install.sh` → resolve `VAULT_VERSION` / `VAULT_IMAGE` /
   `VAULT_INSTALL_DIR` → `docker pull` → `mktemp -d` staging dir →
   `docker run --rm --user … --entrypoint vault-install -v <staging>:/install` → copy
   `vault` into the install dir and completions into `~/.local/share/vault/completion/` →
   `PATH` warning if needed.

Add a short exit codes / messages table for the CLI (usage error 2, runtime/daemon errors 1,
passthrough codes), linking to the README for user-facing wording. Check every step against
`cli/bin/vault`, `cli/lib/*.sh` and `install.sh`.

## Files to Change
- `docs/agents/flow.md` — new `## CLI flow` section (commands and install path).
