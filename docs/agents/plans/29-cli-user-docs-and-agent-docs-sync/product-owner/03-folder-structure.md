# folder-structure.md

Bring `docs/agents/folder-structure.md` in line with the tree:

- **Project Root table:** add `cli/` (`bin/vault`, `lib/*.sh`, `completion/vault.bash`,
  `completion/_vault`; owner `cli`), `install.sh` (the `curl | bash` installer; owner `cli`),
  `build/` (generated, git-ignored: `build/vault` bundle; release assets staged by
  `github_release.sh` if applicable — check the script), and `README.md` / `AGENTS.md` /
  `LICENSE` if the table lists root files. Update `source/` (now also `bin/install.sh` and
  `lib/install.sh`; `entrypoint.sh` is no longer "the only script") and `test/` (`cli/`,
  `install/`, `bash32/`, `scripts/`, `lib/`, `fixture/`, helpers).
- **New `## cli/` section:** `bin/vault` (entry point, `# BEGIN LIBS` / `# END LIBS` block),
  `lib/` libraries with one line each (`args`, `config`, `container`, `docker`, `guardrails`,
  `instance`, `naming`, `output`, `runtime`, `usage`), `completion/`.
- **`source/` section:** add `bin/install.sh` (the `vault-install` entry) and `lib/install.sh`.
- **`scripts/` section:** add `bundle_cli.sh`.
- **Makefile table:** add `bundle-cli`; `build-image` and `release` depend on it; `test`
  covers `test/lib`, `test/cli`, `test/install`, `test/scripts`, the bash 3.2 run and
  `zsh -n`; `lint` covers `cli/` and `install.sh`. Variables: add `ZSH_IMAGE`,
  `SMOKE_TIMEOUT`, `RELEASE_IMAGE`, `PUSH` (match the Makefile and `scripts/test.sh`, e.g.
  `BASH32_TEST_IMAGE`).
- Keep the `docs/agents/` row's note about `specs/` (removed by #30).

## Files to Change
- `docs/agents/folder-structure.md` — root table, new `cli/` section, `source/`, `scripts/`,
  Makefile targets and variables.
