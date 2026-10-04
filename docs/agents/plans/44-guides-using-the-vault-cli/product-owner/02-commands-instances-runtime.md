# Commands, instances and runtime
Add the sections describing what the CLI does:

- **Commands:** `up` (detached by default, `-f` to follow), `down`, `logs [-f]`, `status`,
  `compose <args>`, `run <args>`, `version`, `help`. One short example per command. Document
  exit codes and the message prefixes the CLI prints (from `cli/lib/output.sh` and
  `cli/bin/vault`).
- **Instances:** naming (`vault-<name>` container, `vault-<name>-data` volume), default name
  derivation, `--name`, and the shared-volume warning (link `concepts.md` for persistence).
- **Runtime:** `--runtime auto|sysbox|privileged`, what `auto` detects (`cli/lib/runtime.sh`),
  and the warning printed when falling back to `--privileged` (link `security.md`).

## Files to Change
- `docs/guides/vault/cli.md` — Commands, Instances and Runtime sections.
