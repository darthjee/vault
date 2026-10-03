# shellcheck shell=bash disable=SC2034 # ARGS_* globals are read by callers
# Library: option parsing for the vault CLI commands (bash 3.2: indexed
# arrays only). Results go into ARGS_* globals, set by args_parse.
# Sourcing this file only defines functions.

# Parses the options, [dir] and passthrough arguments of a command.
# Usage: args_parse <command> <args...>
# Commands: up, down, logs, status, compose, run.
# Sets:
#   ARGS_COMMAND                    the command
#   ARGS_NAME, ARGS_NAME_SET        --name (validated), set marker 0/1
#   ARGS_IMAGE, ARGS_IMAGE_SET      --image
#   ARGS_RUNTIME, ARGS_RUNTIME_SET  --runtime (auto|sysbox|privileged)
#   ARGS_STOP_TIMEOUT, ARGS_STOP_TIMEOUT_SET  --stop-timeout (positive integer)
#   ARGS_PORTS, ARGS_PORTS_SET      -p/--port entries (array), given marker
#   ARGS_VOLUMES, ARGS_VOLUMES_SET  -v/--volume entries
#   ARGS_ENVS, ARGS_ENVS_SET        -e/--env entries (never validated)
#   ARGS_ENV_FILES, ARGS_ENV_FILES_SET  --env-file entries
#   ARGS_ATTACH                     1 with -f/--attach (up)
#   ARGS_FOLLOW                     1 with -f/--follow (logs)
#   ARGS_HELP                       1 with -h/--help (parsing stops there)
#   ARGS_DIR, ARGS_DIR_SET          the [dir] positional
#   ARGS_PASSTHROUGH                compose/run arguments (array)
# Returns 0, or 2 on a usage error (message printed on stderr).
args_parse() {
  local command="$1"
  shift
  _args_reset "$command"

  case "$command" in
    up | down | logs | status | compose | run) ;;
    *)
      output_error "unknown command '$command'"
      output_hint 'run "vault help"'
      return 2
      ;;
  esac

  local token opt value inline key
  while [ "$#" -gt 0 ]; do
    token="$1"
    case "$token" in
      --)
        shift
        _args_after_double_dash "$@"
        return
        ;;
      --*=*)
        opt="${token%%=*}"
        value="${token#*=}"
        inline=1
        ;;
      -?*)
        opt="$token"
        value=""
        inline=0
        ;;
      *)
        if _args_stops_at "$token"; then
          _args_passthrough "$@"
          return 0
        fi
        _args_positional "$token" || return
        shift
        continue
        ;;
    esac

    key="$(_args_key "$command" "$opt")"
    if [ -z "$key" ]; then
      output_error "unknown option '$opt'"
      output_hint 'run "vault help"'
      return 2
    fi

    case "$key" in
      help | attach | follow)
        if [ "$inline" -eq 1 ]; then
          _args_bad_value "$opt" "$value"
          return 2
        fi
        _args_flag "$key"
        if [ "$key" = help ]; then
          return 0
        fi
        shift
        continue
        ;;
    esac

    if [ "$inline" -eq 0 ]; then
      if [ "$#" -lt 2 ]; then
        output_error "$opt requires a value"
        return 2
      fi
      value="$2"
      shift
    fi
    _args_store "$key" "$opt" "$value" || return
    shift
  done
  return 0
}

# Returns 0 when <name> is a valid explicit instance name:
# [a-z0-9][a-z0-9_.-]*
# Usage: args_valid_name <name>
args_valid_name() {
  local lower='abcdefghijklmnopqrstuvwxyz0123456789'
  case "$1" in
    "" | [!"$lower"]* | *[!"$lower"_.-]*) return 1 ;;
  esac
  return 0
}

# Returns 0 when <runtime> is auto, sysbox or privileged.
# Usage: args_valid_runtime <runtime>
args_valid_runtime() {
  case "$1" in
    auto | sysbox | privileged) return 0 ;;
  esac
  return 1
}

# Returns 0 when <value> is a positive integer (no sign, no leading zero).
# Usage: args_valid_stop_timeout <value>
args_valid_stop_timeout() {
  case "$1" in
    "" | 0* | *[!0123456789]*) return 1 ;;
  esac
  return 0
}

# Resets every ARGS_* global.
# Usage: _args_reset <command>
_args_reset() {
  ARGS_COMMAND="$1"
  ARGS_NAME=""
  ARGS_NAME_SET=0
  ARGS_IMAGE=""
  ARGS_IMAGE_SET=0
  ARGS_RUNTIME=""
  ARGS_RUNTIME_SET=0
  ARGS_STOP_TIMEOUT=""
  ARGS_STOP_TIMEOUT_SET=0
  ARGS_PORTS=()
  ARGS_PORTS_SET=0
  ARGS_VOLUMES=()
  ARGS_VOLUMES_SET=0
  ARGS_ENVS=()
  ARGS_ENVS_SET=0
  ARGS_ENV_FILES=()
  ARGS_ENV_FILES_SET=0
  ARGS_ATTACH=0
  ARGS_FOLLOW=0
  ARGS_HELP=0
  ARGS_DIR=""
  ARGS_DIR_SET=0
  ARGS_PASSTHROUGH=()
}

# Prints the canonical key of <option> for <command>, or nothing when the
# option is unknown or not valid for the command.
# Usage: _args_key <command> <option>
_args_key() {
  local command="$1" opt="$2"
  case "$opt" in
    -h | --help) echo help ;;
    --name) echo name ;;
    --image) echo image ;;
    --runtime | -p | --port | -v | --volume | -e | --env | --env-file)
      case "$command" in
        up | run) _args_canonical "$opt" ;;
      esac
      ;;
    --stop-timeout)
      case "$command" in
        up | run | down) echo stop-timeout ;;
      esac
      ;;
    -f)
      case "$command" in
        up) echo attach ;;
        logs) echo follow ;;
      esac
      ;;
    --attach) [ "$command" != up ] || echo attach ;;
    --follow) [ "$command" != logs ] || echo follow ;;
  esac
  return 0
}

# Prints the canonical key of a value option.
# Usage: _args_canonical <option>
_args_canonical() {
  case "$1" in
    --runtime) echo runtime ;;
    -p | --port) echo port ;;
    -v | --volume) echo volume ;;
    -e | --env) echo env ;;
    --env-file) echo env-file ;;
  esac
}

# Sets a value-less flag.
# Usage: _args_flag <help|attach|follow>
_args_flag() {
  case "$1" in
    help) ARGS_HELP=1 ;;
    attach) ARGS_ATTACH=1 ;;
    follow) ARGS_FOLLOW=1 ;;
  esac
}

# Validates and stores the value of an option.
# Usage: _args_store <key> <option> <value>
# Returns 2 on a bad value.
_args_store() {
  local key="$1" opt="$2" value="$3"
  case "$key" in
    name)
      args_valid_name "$value" || { _args_bad_value "$opt" "$value"; return 2; }
      ARGS_NAME="$value"
      ARGS_NAME_SET=1
      ;;
    image)
      [ -n "$value" ] || { _args_bad_value "$opt" "$value"; return 2; }
      ARGS_IMAGE="$value"
      ARGS_IMAGE_SET=1
      ;;
    runtime)
      args_valid_runtime "$value" || { _args_bad_value "$opt" "$value"; return 2; }
      ARGS_RUNTIME="$value"
      ARGS_RUNTIME_SET=1
      ;;
    stop-timeout)
      args_valid_stop_timeout "$value" || { _args_bad_value "$opt" "$value"; return 2; }
      ARGS_STOP_TIMEOUT="$value"
      ARGS_STOP_TIMEOUT_SET=1
      ;;
    port)
      [ -n "$value" ] || { _args_bad_value "$opt" "$value"; return 2; }
      ARGS_PORTS+=("$value")
      ARGS_PORTS_SET=1
      ;;
    volume)
      [ -n "$value" ] || { _args_bad_value "$opt" "$value"; return 2; }
      ARGS_VOLUMES+=("$value")
      ARGS_VOLUMES_SET=1
      ;;
    env)
      ARGS_ENVS+=("$value")
      ARGS_ENVS_SET=1
      ;;
    env-file)
      [ -n "$value" ] || { _args_bad_value "$opt" "$value"; return 2; }
      ARGS_ENV_FILES+=("$value")
      ARGS_ENV_FILES_SET=1
      ;;
  esac
  return 0
}

# Returns 0 when parsing stops at the positional <arg> (compose: always;
# run: once [dir] is taken, or when <arg> is not an existing directory).
# Usage: _args_stops_at <arg>
_args_stops_at() {
  case "$ARGS_COMMAND" in
    compose) return 0 ;;
    run)
      [ "$ARGS_DIR_SET" -eq 0 ] && [ -d "$1" ] && return 1
      return 0
      ;;
  esac
  return 1
}

# Takes <arg> as [dir]; a second positional is a usage error (exit 2).
# Usage: _args_positional <arg>
_args_positional() {
  if [ "$ARGS_DIR_SET" -eq 1 ]; then
    output_error "unexpected argument '$1'"
    output_hint 'run "vault help"'
    return 2
  fi
  ARGS_DIR="$1"
  ARGS_DIR_SET=1
}

# Handles the arguments after "--": passthrough for compose/run, else at
# most one [dir].
# Usage: _args_after_double_dash <args...>
_args_after_double_dash() {
  case "$ARGS_COMMAND" in
    compose | run)
      _args_passthrough "$@"
      return 0
      ;;
  esac
  while [ "$#" -gt 0 ]; do
    _args_positional "$1" || return
    shift
  done
  return 0
}

# Stores the passthrough arguments.
# Usage: _args_passthrough <args...>
_args_passthrough() {
  ARGS_PASSTHROUGH=("$@")
}

# Prints the "bad option value" error.
# Usage: _args_bad_value <option> <value>
_args_bad_value() {
  output_error "invalid value for $1: '$2'"
}
