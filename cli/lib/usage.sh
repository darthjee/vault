# shellcheck shell=bash
# Library: usage text for the vault CLI.
# Sourcing this file only defines functions.

# Prints the usage to stdout. Callers redirect it to stderr when needed
# (e.g. "vault" with no command).
# Usage: usage_print
usage_print() {
  cat <<'USAGE'
Usage: vault <command> [options] [dir] [args]

Commands:
  version     Print the CLI version
  help        Print this help

Options:
  -h, --help  Print this help
USAGE
}
