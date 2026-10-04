# bats tests

Add `test/cli/completion.bats`. It runs on `BATS_IMAGE` and on `BASH32_TEST_IMAGE`, because
`scripts/test.sh` runs every suite under `test/cli/`.

- `setup`: `load helpers/docker_stub`, call `docker_stub_setup`, source
  `$BATS_TEST_DIRNAME/../../cli/completion/vault.bash`, and `cd` into a temp dir with a couple of
  subdirectories and files.
- A helper `complete_words <words...>` sets `COMP_WORDS` (the cursor is on the last word),
  `COMP_CWORD`, `COMP_LINE`/`COMP_POINT`, calls `_vault_complete`, and prints `COMPREPLY` one
  entry per line, sorted.
- Cases:
  - `vault ''` → the eight subcommands; `vault st` → `status`;
  - `vault up -` → the `up` options, including `--attach`, `--runtime` and `--stop-timeout`;
    `vault logs -` → includes `--follow`, excludes `--runtime`; `vault status -` excludes `-p`;
  - `vault version ''` and `vault help ''` → nothing;
  - `vault up --runtime ''` → `auto privileged sysbox`; `vault up --runtime s` → `sysbox`;
    the split form (`--runtime`, `=`, `''`) → the three values;
  - `vault up --env-file ''` → files; `vault up -v ''` → files and directories;
  - `vault up ''` → only directories;
  - `vault up --name ''` with `docker_stub_set ps` returning `vault-alpha\nvault-beta` →
    `alpha beta`, and the log shows exactly one `ps` call. With `ps` failing (status 1 and
    stderr), nothing is offered and nothing is printed on stderr;
  - `vault compose dir ''` and `vault run -- ''` → nothing;
  - `vault up --image ''` → nothing.
- shellcheck: the file is covered by `make lint` (`*.bats` under `test/`).

## Files to Change

- `test/cli/completion.bats` — new.
