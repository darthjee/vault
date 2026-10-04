# shellcheck shell=bash
# Bash completion for the vault CLI (bash 3.2+).
# Sourcing this file only defines functions and registers _vault_complete
# for the vault command. Install it in a bash-completion directory, or source
# it from ~/.bashrc.
# bash 3.2: no compopt, associative arrays, mapfile or bash-completion helpers.

# Completes the vault command line from COMP_WORDS / COMP_CWORD into COMPREPLY.
# Usage: complete -F _vault_complete vault
_vault_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local command word i dir_set=0 opts_done=0 value_opt=""
  COMPREPLY=()

  if [ "$COMP_CWORD" -le 1 ]; then
    _vault_complete_words 'up down logs status compose run version help' "$cur"
    return 0
  fi

  command="${COMP_WORDS[1]}"
  case "$command" in
    up | down | logs | status | compose | run) ;;
    *) return 0 ;;
  esac

  # Walk the words before the cursor, as args_parse does.
  i=2
  while [ "$i" -lt "$COMP_CWORD" ]; do
    word="${COMP_WORDS[i]}"
    if [ "$opts_done" -eq 1 ]; then
      dir_set=1
    else
      case "$word" in
        --)
          case "$command" in
            compose | run) return 0 ;;
          esac
          opts_done=1
          ;;
        --*=*) ;;
        -?*)
          if _vault_complete_takes_value "$word"; then
            # "--opt=value" is split into "--opt" "=" "value" by
            # COMP_WORDBREAKS: skip the "=", then the value.
            if [ "${COMP_WORDS[i + 1]-}" = "=" ]; then
              i=$((i + 1))
            fi
            i=$((i + 1))
            if [ "$i" -ge "$COMP_CWORD" ]; then
              value_opt="$word"
              break
            fi
          fi
          ;;
        *)
          case "$command" in
            compose) return 0 ;;
            run)
              if [ "$dir_set" -eq 1 ] || [ ! -d "$word" ]; then
                return 0
              fi
              ;;
          esac
          dir_set=1
          ;;
      esac
    fi
    i=$((i + 1))
  done

  if [ -n "$value_opt" ]; then
    # Cursor right after "--opt=": bash reports the "=" as the current word.
    if [ "$cur" = "=" ]; then
      cur=""
    fi
    _vault_complete_value "$value_opt" "$cur" ""
    return 0
  fi

  if [ "$opts_done" -eq 0 ]; then
    case "$cur" in
      --*=*)
        # "--opt=value" as one word ("=" not in COMP_WORDBREAKS).
        if _vault_complete_takes_value "${cur%%=*}"; then
          _vault_complete_value "${cur%%=*}" "${cur#*=}" "${cur%%=*}="
        fi
        return 0
        ;;
      -*)
        _vault_complete_words "$(_vault_complete_options "$command")" "$cur"
        return 0
        ;;
    esac
  fi

  if [ "$dir_set" -eq 0 ] && [ "$command" != compose ]; then
    _vault_complete_compgen "" -d -- "$cur"
  fi
  return 0
}

# Prints the options accepted by <command> (keep in sync with _args_key in
# cli/lib/args.sh).
# Usage: _vault_complete_options <command>
_vault_complete_options() {
  case "$1" in
    up) echo '--name --image --runtime -p --port -v --volume -e --env --env-file --stop-timeout -f --attach -h --help' ;;
    run) echo '--name --image --runtime -p --port -v --volume -e --env --env-file --stop-timeout -h --help' ;;
    down) echo '--name --image --stop-timeout -h --help' ;;
    logs) echo '--name --image -f --follow -h --help' ;;
    status | compose) echo '--name --image -h --help' ;;
  esac
}

# Returns 0 when <option> takes a value.
# Usage: _vault_complete_takes_value <option>
_vault_complete_takes_value() {
  case "$1" in
    --name | --image | --runtime | -p | --port | -v | --volume | -e | --env | --env-file | --stop-timeout)
      return 0
      ;;
  esac
  return 1
}

# Adds the completions of the value of <option> to COMPREPLY, each one
# prefixed by <prefix>.
# Usage: _vault_complete_value <option> <cur> <prefix>
_vault_complete_value() {
  local opt="$1" cur="$2" prefix="$3"
  case "$opt" in
    --runtime) _vault_complete_words 'auto sysbox privileged' "$cur" "$prefix" ;;
    --env-file | -v | --volume) _vault_complete_compgen "$prefix" -f -- "$cur" ;;
    --name) _vault_complete_words "$(_vault_complete_names)" "$cur" "$prefix" ;;
  esac
  return 0
}

# Prints the vault instance names (without the vault- prefix), one per line.
# Prints nothing, not even on stderr, when docker is missing or fails.
# Usage: _vault_complete_names
_vault_complete_names() {
  local names name
  command -v docker >/dev/null 2>&1 || return 0
  names="$(docker ps -a --filter 'name=^vault-' --format '{{.Names}}' 2>/dev/null)" || return 0
  while IFS= read -r name; do
    case "$name" in
      vault-?*) printf '%s\n' "${name#vault-}" ;;
    esac
  done <<EOF_NAMES
$names
EOF_NAMES
  return 0
}

# Adds the words of <words> matching <cur> to COMPREPLY, prefixed by <prefix>.
# Usage: _vault_complete_words <words> <cur> [prefix]
_vault_complete_words() {
  _vault_complete_compgen "${3-}" -W "$1" -- "$2"
}

# Runs compgen with <args> and adds each output line to COMPREPLY, prefixed
# by <prefix>. Lines are read one by one, so paths with spaces stay whole.
# Usage: _vault_complete_compgen <prefix> <compgen-args...>
_vault_complete_compgen() {
  local prefix="$1" line
  shift
  while IFS= read -r line; do
    COMPREPLY+=("$prefix$line")
  done < <(compgen "$@" 2>/dev/null)
}

complete -F _vault_complete vault
