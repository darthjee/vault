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
  up          Start the instance (detached; -f to stay in the foreground)
  down        Stop and remove the instance (the data volume is kept)
  logs        Show the instance logs (-f to follow)
  status      Show the instance state, image, runtime, ports and env keys
  compose     Run "docker compose <args>" inside the running instance
  run         Run the image once with <args> (docker run --rm)
  version     Print the CLI version
  help        Print this help

Options:
  --name <name>              Instance name (default: the dir's basename)
  --image <image>            Image to run
  --runtime <runtime>        auto, sysbox or privileged (up, run)
  -p, --port <HOST:CONT>     Published port, repeatable (up, run)
  -v, --volume <SRC:DST>     Extra mount, repeatable (up, run)
  -e, --env <KEY=VALUE>      Env var, repeatable (up, run)
  --env-file <file>          Env file, repeatable (up, run)
  --stop-timeout <seconds>   Stop timeout (up, run, down)
  -f, --attach               Run in the foreground (up)
  -f, --follow               Follow the logs (logs)
  -h, --help                 Print this help
USAGE
}
