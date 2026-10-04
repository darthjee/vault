#!/usr/bin/env bats
# Tests for cli/completion/vault.bash (the bash completion function).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub

  docker_stub_setup
  # shellcheck source=SCRIPTDIR/../../cli/completion/vault.bash
  source "$BATS_TEST_DIRNAME/../../cli/completion/vault.bash"

  cd "$BATS_TEST_TMPDIR" || return
  mkdir -p work
  cd work || return
  mkdir -p app "my dir"
  touch app.env "my file.env"
}

# Completes the command line made of <words> (the cursor is at the end of the
# last word) and prints COMPREPLY, one entry per line, sorted.
# Usage: complete_words <words...>
complete_words() {
  COMP_WORDS=("$@")
  COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
  COMP_LINE="$*"
  COMP_POINT=${#COMP_LINE}
  COMPREPLY=()
  _vault_complete
  if [ "${#COMPREPLY[@]}" -gt 0 ]; then
    printf '%s\n' "${COMPREPLY[@]}" | LC_ALL=C sort
  fi
}

@test "sourcing registers _vault_complete for vault" {
  run complete -p vault

  assert_success
  assert_output "complete -F _vault_complete vault"
}

@test "position 1 offers the eight subcommands" {
  run complete_words vault ''

  assert_success
  assert_output "compose
down
help
logs
run
status
up
version"
}

@test "position 1 filters the subcommands by prefix" {
  run complete_words vault st

  assert_success
  assert_output status
}

@test "up offers its options" {
  run complete_words vault up -

  assert_success
  assert_output "--attach
--env
--env-file
--help
--image
--name
--port
--runtime
--stop-timeout
--volume
-e
-f
-h
-p
-v"
}

@test "run offers its options, without -f" {
  run complete_words vault run -

  assert_success
  assert_line -- --runtime
  assert_line -- --stop-timeout
  assert_line -- --env-file
  refute_line -- -f
  refute_line -- --attach
}

@test "down offers --stop-timeout but no up-only option" {
  run complete_words vault down -

  assert_success
  assert_output "--help
--image
--name
--stop-timeout
-h"
}

@test "logs offers --follow and not --runtime" {
  run complete_words vault logs -

  assert_success
  assert_line -- --follow
  assert_line -- -f
  refute_line -- --runtime
  refute_line -- --attach
}

@test "status and compose offer --name, --image and the help only" {
  local command
  for command in status compose; do
    run complete_words vault "$command" -

    assert_success
    assert_output "--help
--image
--name
-h"
  done
}

@test "options after a value option and its value are still offered" {
  run complete_words vault up --image img:1 --run

  assert_success
  assert_output --runtime
}

@test "version and help offer nothing" {
  run complete_words vault version ''
  assert_success
  assert_output ""

  run complete_words vault help ''
  assert_success
  assert_output ""

  run complete_words vault help -
  assert_success
  assert_output ""
}

@test "--runtime offers the runtimes" {
  run complete_words vault up --runtime ''

  assert_success
  assert_output "auto
privileged
sysbox"
}

@test "--runtime filters the runtimes by prefix" {
  run complete_words vault run --runtime s

  assert_success
  assert_output sysbox
}

@test "--runtime=<TAB>, split on '=', offers the runtimes" {
  run complete_words vault up --runtime = ''

  assert_success
  assert_output "auto
privileged
sysbox"
}

@test "--runtime=<TAB> with the cursor on '=' offers the runtimes" {
  run complete_words vault up --runtime =

  assert_success
  assert_output "auto
privileged
sysbox"
}

@test "--runtime=p, split on '=', filters the runtimes" {
  run complete_words vault up --runtime = p

  assert_success
  assert_output privileged
}

@test "--runtime=s as one word offers the prefixed value" {
  run complete_words vault up --runtime=s

  assert_success
  assert_output --runtime=sysbox
}

@test "a split --runtime=value is skipped before the next word" {
  run complete_words vault up --runtime = auto ''

  assert_success
  assert_output "app
my dir"
}

@test "--env-file offers files and directories, spaces kept" {
  run complete_words vault up --env-file ''

  assert_success
  assert_output "app
app.env
my dir
my file.env"
}

@test "--env-file filters files by prefix" {
  run complete_words vault up --env-file app.

  assert_success
  assert_output app.env
}

@test "-v and --volume offer files and directories" {
  local opt
  for opt in -v --volume; do
    run complete_words vault up "$opt" ''

    assert_success
    assert_output "app
app.env
my dir
my file.env"
  done
}

@test "[dir] offers only directories" {
  run complete_words vault up ''

  assert_success
  assert_output "app
my dir"
}

@test "[dir] filters directories by prefix" {
  run complete_words vault down m

  assert_success
  assert_output "my dir"
}

@test "nothing is offered once [dir] is set" {
  run complete_words vault up app ''

  assert_success
  assert_output ""
}

@test "--name offers the vault instances without the prefix, one docker ps call" {
  docker_stub_set ps "vault-alpha
vault-beta"

  run complete_words vault up --name ''

  assert_success
  assert_output "alpha
beta"
  assert_equal "$(docker_stub_count ps)" 1
  assert_equal "$(docker_stub_calls | wc -l | tr -d ' ')" 1
  assert_docker_called ps -a --filter 'name=^vault-' --format '{{.Names}}'
}

@test "--name filters the instances by prefix" {
  docker_stub_set ps "vault-alpha
vault-beta"

  run complete_words vault logs --name b

  assert_success
  assert_output beta
}

@test "--name offers nothing and prints nothing when docker ps fails" {
  docker_stub_set ps "" 1 "Cannot connect to the Docker daemon"

  run --separate-stderr complete_words vault up --name ''

  assert_success
  assert_output ""
  assert_equal "$stderr" ""
}

@test "--name offers nothing and prints nothing when docker is missing" {
  docker_stub_hide

  run --separate-stderr complete_words vault up --name ''

  assert_success
  assert_output ""
  assert_equal "$stderr" ""
}

@test "compose passthrough arguments complete nothing" {
  run complete_words vault compose app ''
  assert_success
  assert_output ""

  run complete_words vault compose ps -
  assert_success
  assert_output ""
}

@test "run completes nothing after --" {
  run complete_words vault run -- ''
  assert_success
  assert_output ""

  run complete_words vault run -- -
  assert_success
  assert_output ""
}

@test "run completes nothing after [dir] and a compose argument" {
  run complete_words vault run app config ''

  assert_success
  assert_output ""
}

@test "run completes nothing after a first argument that is not a directory" {
  run complete_words vault run config ''

  assert_success
  assert_output ""
}

@test "free-form option values complete nothing" {
  local opt
  for opt in --image -p --port -e --env --stop-timeout; do
    run complete_words vault up "$opt" ''

    assert_success
    assert_output ""
  done
}

@test "an unknown command completes nothing" {
  run complete_words vault nope ''

  assert_success
  assert_output ""
}
