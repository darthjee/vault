# AGENTS.md

- **Intro / Stack:** mention the `vault` CLI (bash 3.2+, Linux and macOS) next to the image;
  add the bash 3.2 test image (`test/bash32/`) and `ZSH_IMAGE` (`zsh -n`) to the stack/tooling
  lines.
- **Design:** add a `### CLI` subsection after "Runtime flow" (or after "Conventions"):
  - what it is: a client that builds `docker run` for the user; source `cli/bin/vault` +
    `cli/lib/*.sh`, bundled into `build/vault` by `scripts/bundle_cli.sh` (`make bundle-cli`),
    shipped in the image as `/usr/local/bin/vault`;
  - instance identity (`vault-<name>`, `vault-<name>-data`), commands, runtime selection
    (auto/sysbox/privileged, fallback warning, never escalate, rootless refused), guardrails;
  - configuration (`.vaultrc` parsed, never sourced; `.vault.env`; precedence);
  - privilege model (no `sudo`, writes nothing on the host except `install.sh`);
  - distribution: `install.sh` → `docker run --entrypoint vault-install` → copies the CLI and
    completions; GitHub release assets; `VAULT_VERSION` line stamped/checked by
    `bump_version.sh` / `check_tag_version.sh` in `cli/bin/vault` and `install.sh`.
  Keep it a design summary and link to `flow.md` / `architecture.md` for details.
- **Release:** check the `check-version-tag` bullet mentions the `VAULT_VERSION` lines, and
  the Makefile targets list includes `bundle-cli`; variables include `ZSH_IMAGE`,
  `SMOKE_TIMEOUT`, `RELEASE_IMAGE`, `PUSH` if they are user-facing (match the Makefile).
- **Future work:** remove the CLI item; add the spec's still-relevant future items:
  `vault up --wait`, a Homebrew tap, Windows support, `vault build` / `vault pack`,
  self-update and uninstall, `vault ls`, remote Docker hosts (`DOCKER_HOST`, contexts),
  coloured output. "Sysbox in CI" is already listed; keep a single entry.
- **Agents table:** `cli` is already listed — verify its scope matches
  `.claude/agents/cli.md` and leave it.
- Keep the `specs/` documentation row and the "During epic #20 … overrides" note (#30
  removes them).

## Files to Change
- `AGENTS.md` — CLI design subsection, Stack, Release/Makefile list, Future work.
