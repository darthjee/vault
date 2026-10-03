# shellcheck shell=bash
# Library: diagnostics for the vault CLI.
# Each helper prints one line to stderr, prefixed "vault: <level>: ".
# Sourcing this file only defines functions.

# Prints an error line to stderr.
# Usage: output_error <message>
output_error() {
  _output_print error "$*"
}

# Prints a warning line to stderr.
# Usage: output_warning <message>
output_warning() {
  _output_print warning "$*"
}

# Prints a hint line to stderr (on its own line, after its error).
# Usage: output_hint <message>
output_hint() {
  _output_print hint "$*"
}

# Prints "vault: <level>: <message>" to stderr.
# Usage: _output_print <level> <message>
_output_print() {
  printf 'vault: %s: %s\n' "$1" "$2" >&2
}
