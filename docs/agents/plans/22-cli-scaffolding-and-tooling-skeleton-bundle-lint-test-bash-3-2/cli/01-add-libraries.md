# Add the output and usage libraries
Create the first two CLI libraries. They only define functions; sourcing them has no side
effects, so the bundle can concatenate them safely.

- `output.sh`: `output_error`, `output_warning`, `output_hint`, each printing one line to stderr
  prefixed `vault: error: `, `vault: warning: `, `vault: hint: `.
- `usage.sh`: `usage_print`, printing the usage to stdout. For now it lists `version` and `help`
  (and `-h` / `--help`); later sub-issues extend it with their commands.

## Files to Change
- `cli/lib/output.sh` — new; diagnostic helpers.
- `cli/lib/usage.sh` — new; usage text.
