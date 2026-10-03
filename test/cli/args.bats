#!/usr/bin/env bats
# Tests for cli/lib/args.sh (option parsing).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  ROOT="$BATS_TEST_DIRNAME/../.."
  # shellcheck source=SCRIPTDIR/../../cli/lib/output.sh
  source "$ROOT/cli/lib/output.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/args.sh
  source "$ROOT/cli/lib/args.sh"

  cd "$BATS_TEST_TMPDIR" || return
  mkdir -p app "my dir"
}

# Runs args_parse with the given args and asserts a usage error (exit 2)
# with the given stderr.
# Usage: check_usage_error <expected-stderr> <command> <args...>
check_usage_error() {
  local expected="$1"
  shift
  run --separate-stderr args_parse "$@"

  assert_failure 2
  assert_output ""
  assert_equal "$stderr" "$expected"
}

@test "long options accept --opt value and --opt=value" {
  args_parse up --name app1 --image=img:1 --runtime sysbox --stop-timeout=30

  assert_equal "$ARGS_COMMAND" up
  assert_equal "$ARGS_NAME" app1
  assert_equal "$ARGS_NAME_SET" 1
  assert_equal "$ARGS_IMAGE" img:1
  assert_equal "$ARGS_IMAGE_SET" 1
  assert_equal "$ARGS_RUNTIME" sysbox
  assert_equal "$ARGS_RUNTIME_SET" 1
  assert_equal "$ARGS_STOP_TIMEOUT" 30
  assert_equal "$ARGS_STOP_TIMEOUT_SET" 1
}

@test "nothing given leaves every marker unset" {
  args_parse up

  assert_equal "$ARGS_NAME_SET" 0
  assert_equal "$ARGS_IMAGE_SET" 0
  assert_equal "$ARGS_RUNTIME_SET" 0
  assert_equal "$ARGS_STOP_TIMEOUT_SET" 0
  assert_equal "$ARGS_PORTS_SET" 0
  assert_equal "$ARGS_VOLUMES_SET" 0
  assert_equal "$ARGS_ENVS_SET" 0
  assert_equal "$ARGS_ENV_FILES_SET" 0
  assert_equal "$ARGS_DIR_SET" 0
  assert_equal "${#ARGS_PORTS[@]}" 0
  assert_equal "${#ARGS_PASSTHROUGH[@]}" 0
  assert_equal "$ARGS_ATTACH" 0
  assert_equal "$ARGS_HELP" 0
}

@test "repeatable options keep every entry in order, values with spaces intact" {
  args_parse run -p 3000:80 --port=3443:443 -v "/a b:/c" --volume /d:/e \
    -e "A=x y" --env B --env-file "f 1" --env-file=f2

  assert_equal "${#ARGS_PORTS[@]}" 2
  assert_equal "${ARGS_PORTS[0]}" 3000:80
  assert_equal "${ARGS_PORTS[1]}" 3443:443
  assert_equal "$ARGS_PORTS_SET" 1
  assert_equal "${#ARGS_VOLUMES[@]}" 2
  assert_equal "${ARGS_VOLUMES[0]}" "/a b:/c"
  assert_equal "${ARGS_VOLUMES[1]}" /d:/e
  assert_equal "$ARGS_VOLUMES_SET" 1
  assert_equal "${#ARGS_ENVS[@]}" 2
  assert_equal "${ARGS_ENVS[0]}" "A=x y"
  assert_equal "${ARGS_ENVS[1]}" B
  assert_equal "$ARGS_ENVS_SET" 1
  assert_equal "${#ARGS_ENV_FILES[@]}" 2
  assert_equal "${ARGS_ENV_FILES[0]}" "f 1"
  assert_equal "${ARGS_ENV_FILES[1]}" f2
  assert_equal "$ARGS_ENV_FILES_SET" 1
}

@test "an --opt=value value keeps every later =" {
  args_parse up -e "K=a=b" --env=X=1=2

  assert_equal "${ARGS_ENVS[0]}" "K=a=b"
  assert_equal "${ARGS_ENVS[1]}" "X=1=2"
}

@test "-e values are never validated: an empty value is accepted" {
  args_parse up -e ""

  assert_equal "${#ARGS_ENVS[@]}" 1
  assert_equal "${ARGS_ENVS[0]}" ""
}

@test "-f is --attach on up" {
  args_parse up -f
  assert_equal "$ARGS_ATTACH" 1

  args_parse up --attach
  assert_equal "$ARGS_ATTACH" 1
  assert_equal "$ARGS_FOLLOW" 0
}

@test "-f is --follow on logs" {
  args_parse logs -f
  assert_equal "$ARGS_FOLLOW" 1

  args_parse logs --follow
  assert_equal "$ARGS_FOLLOW" 1
  assert_equal "$ARGS_ATTACH" 0
}

@test "-h and --help set ARGS_HELP on every command" {
  local command
  for command in up down logs status compose run; do
    args_parse "$command" -h
    assert_equal "$ARGS_HELP" 1
    args_parse "$command" --name x --help
    assert_equal "$ARGS_HELP" 1
  done
}

@test "up/down/logs/status: options and [dir] in any order" {
  local command
  for command in up down logs status; do
    args_parse "$command" app --name x
    assert_equal "$ARGS_DIR" app
    assert_equal "$ARGS_DIR_SET" 1
    assert_equal "$ARGS_NAME" x

    args_parse "$command" --name y "my dir"
    assert_equal "$ARGS_DIR" "my dir"
    assert_equal "$ARGS_NAME" y
  done
}

@test "up: [dir] need not exist at parse time" {
  args_parse up missing

  assert_equal "$ARGS_DIR" missing
}

@test "up: a second positional is a usage error" {
  check_usage_error "vault: error: unexpected argument 'b'
vault: hint: run \"vault help\"" up a b
}

@test "up: -- ends options, the next argument is [dir]" {
  args_parse up --name x -- -weird

  assert_equal "$ARGS_DIR" -weird
  assert_equal "$ARGS_NAME" x
}

@test "up: -- with two arguments is a usage error" {
  check_usage_error "vault: error: unexpected argument 'b'
vault: hint: run \"vault help\"" up -- a b
}

@test "compose: parsing stops at the first non-option" {
  args_parse compose --name x ps -a --name y

  assert_equal "$ARGS_NAME" x
  assert_equal "$ARGS_DIR_SET" 0
  assert_equal "${#ARGS_PASSTHROUGH[@]}" 4
  assert_equal "${ARGS_PASSTHROUGH[0]}" ps
  assert_equal "${ARGS_PASSTHROUGH[1]}" -a
  assert_equal "${ARGS_PASSTHROUGH[2]}" --name
  assert_equal "${ARGS_PASSTHROUGH[3]}" y
}

@test "compose: an existing directory is still a compose argument" {
  args_parse compose app

  assert_equal "$ARGS_DIR_SET" 0
  assert_equal "${ARGS_PASSTHROUGH[0]}" app
}

@test "compose: -- passes the rest verbatim" {
  args_parse compose -- --help x

  assert_equal "$ARGS_HELP" 0
  assert_equal "${#ARGS_PASSTHROUGH[@]}" 2
  assert_equal "${ARGS_PASSTHROUGH[0]}" --help
  assert_equal "${ARGS_PASSTHROUGH[1]}" x
}

@test "run: the first positional is [dir] when it is an existing directory" {
  args_parse run app -p 1:2 config --x

  assert_equal "$ARGS_DIR" app
  assert_equal "$ARGS_DIR_SET" 1
  assert_equal "${ARGS_PORTS[0]}" 1:2
  assert_equal "${#ARGS_PASSTHROUGH[@]}" 2
  assert_equal "${ARGS_PASSTHROUGH[0]}" config
  assert_equal "${ARGS_PASSTHROUGH[1]}" --x
}

@test "run: the first positional is a compose argument when it is not a directory" {
  args_parse run config -p 1:2

  assert_equal "$ARGS_DIR_SET" 0
  assert_equal "${#ARGS_PORTS[@]}" 0
  assert_equal "${#ARGS_PASSTHROUGH[@]}" 3
  assert_equal "${ARGS_PASSTHROUGH[0]}" config
  assert_equal "${ARGS_PASSTHROUGH[1]}" -p
  assert_equal "${ARGS_PASSTHROUGH[2]}" 1:2
}

@test "run: a second existing directory is a compose argument" {
  args_parse run app "my dir"

  assert_equal "$ARGS_DIR" app
  assert_equal "${#ARGS_PASSTHROUGH[@]}" 1
  assert_equal "${ARGS_PASSTHROUGH[0]}" "my dir"
}

@test "run: -- makes an existing directory a compose argument" {
  args_parse run -- app

  assert_equal "$ARGS_DIR_SET" 0
  assert_equal "${ARGS_PASSTHROUGH[0]}" app
}

@test "run: [dir] then -- passes the rest" {
  args_parse run app -- -p x

  assert_equal "$ARGS_DIR" app
  assert_equal "${#ARGS_PORTS[@]}" 0
  assert_equal "${ARGS_PASSTHROUGH[0]}" -p
  assert_equal "${ARGS_PASSTHROUGH[1]}" x
}

@test "run: no compose arguments leaves the passthrough empty" {
  args_parse run app

  assert_equal "${#ARGS_PASSTHROUGH[@]}" 0
}

@test "an unknown option fails with the hint (exit 2)" {
  check_usage_error "vault: error: unknown option '--nope'
vault: hint: run \"vault help\"" up --nope
}

@test "an unknown --opt=value names the option only" {
  check_usage_error "vault: error: unknown option '--bogus'
vault: hint: run \"vault help\"" up --bogus=xyz
}

@test "options outside their command are unknown" {
  check_usage_error "vault: error: unknown option '-p'
vault: hint: run \"vault help\"" down -p 1:2
  check_usage_error "vault: error: unknown option '--runtime'
vault: hint: run \"vault help\"" logs --runtime auto
  check_usage_error "vault: error: unknown option '--stop-timeout'
vault: hint: run \"vault help\"" status --stop-timeout 5
  check_usage_error "vault: error: unknown option '-f'
vault: hint: run \"vault help\"" run -f
  check_usage_error "vault: error: unknown option '--attach'
vault: hint: run \"vault help\"" logs --attach
  check_usage_error "vault: error: unknown option '--follow'
vault: hint: run \"vault help\"" up --follow
  check_usage_error "vault: error: unknown option '-e'
vault: hint: run \"vault help\"" compose -e A=1
}

@test "--stop-timeout is accepted by down" {
  args_parse down --stop-timeout 5

  assert_equal "$ARGS_STOP_TIMEOUT" 5
}

@test "a missing value fails (exit 2)" {
  check_usage_error "vault: error: --name requires a value" up --name
  check_usage_error "vault: error: -p requires a value" run -p
  check_usage_error "vault: error: --env-file requires a value" up --env-file
}

@test "a flag given a value is a bad value" {
  check_usage_error "vault: error: invalid value for --attach: 'yes'" up --attach=yes
}

@test "--runtime outside auto|sysbox|privileged is a bad value" {
  check_usage_error "vault: error: invalid value for --runtime: 'foo'" up --runtime foo
  check_usage_error "vault: error: invalid value for --runtime: ''" up --runtime=
}

@test "--runtime accepts auto, sysbox and privileged" {
  local runtime
  for runtime in auto sysbox privileged; do
    args_parse run --runtime "$runtime"
    assert_equal "$ARGS_RUNTIME" "$runtime"
  done
}

@test "--stop-timeout must be a positive integer" {
  local value
  for value in 0 -1 1.5 abc "" 007 " 5"; do
    check_usage_error "vault: error: invalid value for --stop-timeout: '$value'" up --stop-timeout "$value"
  done
}

@test "an invalid explicit --name is a bad value, never altered" {
  local value
  for value in My-App "a b" -x _x .x "" "app!"; do
    check_usage_error "vault: error: invalid value for --name: '$value'" up "--name=$value"
  done
}

@test "a valid explicit --name is kept as is" {
  args_parse up --name 0a_b.c-d

  assert_equal "$ARGS_NAME" 0a_b.c-d
}

@test "empty --image, -p, -v and --env-file values are bad values" {
  check_usage_error "vault: error: invalid value for --image: ''" up --image ""
  check_usage_error "vault: error: invalid value for -p: ''" up -p ""
  check_usage_error "vault: error: invalid value for --volume: ''" up --volume=
  check_usage_error "vault: error: invalid value for --env-file: ''" up --env-file ""
}

@test "args_valid_name, args_valid_runtime and args_valid_stop_timeout" {
  args_valid_name a
  run args_valid_name A
  assert_failure
  args_valid_runtime privileged
  run args_valid_runtime Auto
  assert_failure
  args_valid_stop_timeout 60
  run args_valid_stop_timeout 0
  assert_failure
}

@test "an unsupported command is rejected" {
  check_usage_error "vault: error: unknown command 'nope'
vault: hint: run \"vault help\"" nope
}
