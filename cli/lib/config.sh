# shellcheck shell=bash disable=SC2034 # CONFIG_* globals are read by callers
# Library: .vaultrc parsing, precedence (flags > .vaultrc > defaults) and
# .vault.env placement. The parser reads .vaultrc from stdin: it opens no
# file and reads no environment variable.
# Sourcing this file only defines functions.

# Clears the parsed .vaultrc values (CONFIG_RC_*), as for a missing file.
# Usage: config_reset
config_reset() {
  CONFIG_RC_NAME=""
  CONFIG_RC_NAME_SET=0
  CONFIG_RC_IMAGE=""
  CONFIG_RC_IMAGE_SET=0
  CONFIG_RC_RUNTIME=""
  CONFIG_RC_RUNTIME_SET=0
  CONFIG_RC_STOP_TIMEOUT=""
  CONFIG_RC_STOP_TIMEOUT_SET=0
  CONFIG_RC_PORTS=()
  CONFIG_RC_VOLUMES=()
  CONFIG_RC_ENVS=()
  CONFIG_RC_ENV_FILES=()
}

# Parses .vaultrc lines from stdin into CONFIG_RC_*.
# Usage: config_parse <vaultrc-dir> < .vaultrc
#   vaultrc-dir: the directory holding .vaultrc (absolute), used to resolve
#   relative volume sources and env-file paths.
# Sets: CONFIG_RC_NAME(_SET), CONFIG_RC_IMAGE(_SET), CONFIG_RC_RUNTIME(_SET),
#   CONFIG_RC_STOP_TIMEOUT(_SET) (scalars, the last line wins), and the
#   arrays CONFIG_RC_PORTS, CONFIG_RC_VOLUMES, CONFIG_RC_ENVS,
#   CONFIG_RC_ENV_FILES (file order).
# Unknown keys warn and are skipped. Returns 1 on a line without "=" or a
# known key with an invalid value (the error names the line).
config_parse() {
  local dir="$1"
  local line key value number=0

  config_reset
  while IFS= read -r line || [ -n "$line" ]; do
    number=$((number + 1))
    case "$line" in
      "#"*) continue ;;
      *[![:space:]]*) ;;
      *) continue ;;
    esac
    case "$line" in
      *=*) ;;
      *)
        output_error ".vaultrc:$number: expected key=value"
        return 1
        ;;
    esac
    key="${line%%=*}"
    value="${line#*=}"
    _config_set "$dir" "$number" "$key" "$value" || return
  done
  return 0
}

# Merges flags (ARGS_*), .vaultrc (CONFIG_RC_*) and the defaults into the
# final values. Scalars: flag, else .vaultrc, else default. Lists: any flag
# replaces every .vaultrc entry of that key.
# Usage: config_merge <vault-version>
# Sets: CONFIG_NAME ("" when neither --name nor name= is given),
#   CONFIG_IMAGE (default darthjee/vault:<vault-version>), CONFIG_RUNTIME
#   (default auto), CONFIG_STOP_TIMEOUT (default 60), and the arrays
#   CONFIG_PORTS (default 3000:80 when no source gives a port),
#   CONFIG_VOLUMES, CONFIG_ENVS, CONFIG_ENV_FILES.
config_merge() {
  local version="$1"

  CONFIG_NAME="$(_config_pick "$ARGS_NAME_SET" "$ARGS_NAME" "$CONFIG_RC_NAME_SET" "$CONFIG_RC_NAME" "")"
  CONFIG_IMAGE="$(_config_pick "$ARGS_IMAGE_SET" "$ARGS_IMAGE" "$CONFIG_RC_IMAGE_SET" "$CONFIG_RC_IMAGE" "darthjee/vault:$version")"
  CONFIG_RUNTIME="$(_config_pick "$ARGS_RUNTIME_SET" "$ARGS_RUNTIME" "$CONFIG_RC_RUNTIME_SET" "$CONFIG_RC_RUNTIME" auto)"
  CONFIG_STOP_TIMEOUT="$(_config_pick "$ARGS_STOP_TIMEOUT_SET" "$ARGS_STOP_TIMEOUT" "$CONFIG_RC_STOP_TIMEOUT_SET" "$CONFIG_RC_STOP_TIMEOUT" 60)"

  if [ "$ARGS_PORTS_SET" = 1 ]; then
    CONFIG_PORTS=(${ARGS_PORTS[@]+"${ARGS_PORTS[@]}"})
  else
    CONFIG_PORTS=(${CONFIG_RC_PORTS[@]+"${CONFIG_RC_PORTS[@]}"})
  fi
  if [ "${#CONFIG_PORTS[@]}" -eq 0 ]; then
    CONFIG_PORTS=(3000:80)
  fi

  if [ "$ARGS_VOLUMES_SET" = 1 ]; then
    CONFIG_VOLUMES=(${ARGS_VOLUMES[@]+"${ARGS_VOLUMES[@]}"})
  else
    CONFIG_VOLUMES=(${CONFIG_RC_VOLUMES[@]+"${CONFIG_RC_VOLUMES[@]}"})
  fi

  if [ "$ARGS_ENVS_SET" = 1 ]; then
    CONFIG_ENVS=(${ARGS_ENVS[@]+"${ARGS_ENVS[@]}"})
  else
    CONFIG_ENVS=(${CONFIG_RC_ENVS[@]+"${CONFIG_RC_ENVS[@]}"})
  fi

  if [ "$ARGS_ENV_FILES_SET" = 1 ]; then
    CONFIG_ENV_FILES=(${ARGS_ENV_FILES[@]+"${ARGS_ENV_FILES[@]}"})
  else
    CONFIG_ENV_FILES=(${CONFIG_RC_ENV_FILES[@]+"${CONFIG_RC_ENV_FILES[@]}"})
  fi
  return 0
}

# Puts <dir>/.vault.env first in CONFIG_ENV_FILES when it exists, before
# every env-file / --env-file (a --env-file flag never replaces it). Its
# content is never read. Call after config_merge.
# Usage: config_vault_env <dir> <exists 0|1>
#   (the caller tests [ -f "<dir>/.vault.env" ])
config_vault_env() {
  local dir="$1" exists="$2"
  if [ "$exists" = 1 ]; then
    CONFIG_ENV_FILES=("${dir%/}/.vault.env" ${CONFIG_ENV_FILES[@]+"${CONFIG_ENV_FILES[@]}"})
  fi
  return 0
}

# Validates and stores one .vaultrc entry.
# Usage: _config_set <vaultrc-dir> <line-number> <key> <value>
_config_set() {
  local dir="$1" number="$2" key="$3" value="$4"
  case "$key" in
    name)
      args_valid_name "$value" || { _config_bad_value "$number" "$key" "$value"; return 1; }
      CONFIG_RC_NAME="$value"
      CONFIG_RC_NAME_SET=1
      ;;
    image)
      [ -n "$value" ] || { _config_bad_value "$number" "$key" "$value"; return 1; }
      CONFIG_RC_IMAGE="$value"
      CONFIG_RC_IMAGE_SET=1
      ;;
    runtime)
      args_valid_runtime "$value" || { _config_bad_value "$number" "$key" "$value"; return 1; }
      CONFIG_RC_RUNTIME="$value"
      CONFIG_RC_RUNTIME_SET=1
      ;;
    stop-timeout)
      args_valid_stop_timeout "$value" || { _config_bad_value "$number" "$key" "$value"; return 1; }
      CONFIG_RC_STOP_TIMEOUT="$value"
      CONFIG_RC_STOP_TIMEOUT_SET=1
      ;;
    port)
      [ -n "$value" ] || { _config_bad_value "$number" "$key" "$value"; return 1; }
      CONFIG_RC_PORTS+=("$value")
      ;;
    volume)
      [ -n "$value" ] || { _config_bad_value "$number" "$key" "$value"; return 1; }
      CONFIG_RC_VOLUMES+=("$(_config_resolve_volume "$dir" "$value")")
      ;;
    env)
      CONFIG_RC_ENVS+=("$value")
      ;;
    env-file)
      [ -n "$value" ] || { _config_bad_value "$number" "$key" "$value"; return 1; }
      CONFIG_RC_ENV_FILES+=("$(_config_resolve_path "$dir" "$value")")
      ;;
    *)
      output_warning ".vaultrc:$number: unknown key '$key'"
      ;;
  esac
  return 0
}

# Prints the flag value when set, else the .vaultrc value when set, else
# the default.
# Usage: _config_pick <flag-set> <flag> <rc-set> <rc> <default>
_config_pick() {
  if [ "$1" = 1 ]; then
    printf '%s\n' "$2"
  elif [ "$3" = 1 ]; then
    printf '%s\n' "$4"
  else
    printf '%s\n' "$5"
  fi
}

# Prints a volume with a relative source resolved against <dir>.
# The source is the text before the first ":"; with no ":", the value is a
# container path (anonymous volume) and stays as is. A source is relative
# when it starts with "." or contains "/" without a leading "/"; a bare
# name ("data") is a named volume and stays as is.
# Usage: _config_resolve_volume <dir> <volume>
_config_resolve_volume() {
  local dir="$1" volume="$2" source rest
  case "$volume" in
    *:*) ;;
    *)
      printf '%s\n' "$volume"
      return 0
      ;;
  esac
  source="${volume%%:*}"
  rest="${volume#*:}"
  case "$source" in
    /*) ;;
    .* | */*) source="$(_config_resolve_path "$dir" "$source")" ;;
  esac
  printf '%s:%s\n' "$source" "$rest"
}

# Prints <path> resolved against <dir> when it is relative (no leading
# "/"); a leading "./" is dropped.
# Usage: _config_resolve_path <dir> <path>
_config_resolve_path() {
  local dir="$1" path="$2"
  case "$path" in
    /*)
      printf '%s\n' "$path"
      return 0
      ;;
  esac
  while [ "${path#./}" != "$path" ]; do
    path="${path#./}"
  done
  if [ "$path" = . ] || [ -z "$path" ]; then
    printf '%s\n' "${dir%/}"
  else
    printf '%s/%s\n' "${dir%/}" "$path"
  fi
}

# Prints the ".vaultrc bad value" error.
# Usage: _config_bad_value <line-number> <key> <value>
_config_bad_value() {
  output_error ".vaultrc:$1: invalid value for $2: '$3'"
}
