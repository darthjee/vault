# Parse --log-opt

Register `--log-opt` as a repeatable value option of `up` and `run` in `cli/lib/args.sh`, following the issue's "Implementation notes → cli/lib/args.sh":

- `_args_reset`: `ARGS_LOG_OPTS=()`, `ARGS_LOG_OPTS_SET=0`.
- `_args_key`: add `--log-opt` to the `up | run` group (both `--log-opt v` and `--log-opt=v` spellings come for free from the existing parser).
- `_args_canonical`: `--log-opt) echo log-opt ;;`.
- `_args_store`: a `log-opt` branch modelled on `port`, rejecting anything that does not match `?*=*` via `_args_bad_value` (return 2); store verbatim, set the marker.
- Extend the `args_parse` header comment with the two new globals.

Tests in `test/cli/args.bats` (issue "Testing → test/cli/args.bats"): repeatable and ordered on `up`/`run`; `--log-opt=value` form; rejected by `down`, `logs`, `status`, `compose` (extend "options outside their command are unknown"); empty value, value without `=`, empty key (`=10m`) and `--log-opt max-size 10m` are bad values (exit 2, `invalid value for --log-opt: '<value>'`); "nothing given" asserts `ARGS_LOG_OPTS_SET=0` and an empty array.

## Files to Change
- `cli/lib/args.sh` — new globals, key registration, canonical name, storage with structural validation.
- `test/cli/args.bats` — new and extended cases.
