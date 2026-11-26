#!/usr/bin/env bats
# Tests for cli/lib/instance.sh (instance state and TTY flags).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub

  ROOT="$BATS_TEST_DIRNAME/../.."
  # shellcheck source=SCRIPTDIR/../../cli/lib/output.sh
  source "$ROOT/cli/lib/output.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/docker.sh
  source "$ROOT/cli/lib/docker.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/naming.sh
  source "$ROOT/cli/lib/naming.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/instance.sh
  source "$ROOT/cli/lib/instance.sh"
  docker_stub_setup

  NO_SUCH='Error response from daemon: No such object: vault-app'
  DAEMON_DOWN='Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?'
}

@test "instance_state calls docker inspect once with the running format" {
  docker_stub_set inspect true

  instance_state app

  assert_equal "$(docker_stub_count inspect)" 1
  assert_docker_called inspect --format '{{.State.Running}}' vault-app
}

@test "instance_state reports running" {
  docker_stub_set inspect true

  instance_state app

  assert_equal "$INSTANCE_STATE" running
}

@test "instance_state reports stopped" {
  docker_stub_set inspect false

  run --separate-stderr instance_state app
  assert_success
  assert_equal "$stderr" ""

  instance_state app
  assert_equal "$INSTANCE_STATE" stopped
}

@test "instance_state reports missing on No such object, without docker's error" {
  docker_stub_set inspect "" 1 "$NO_SUCH"

  run --separate-stderr instance_state app
  assert_success
  assert_output ""
  assert_equal "$stderr" ""

  instance_state app 2>/dev/null
  assert_equal "$INSTANCE_STATE" missing
}

@test "instance_state reports missing on the lowercase no such object of newer docker" {
  docker_stub_set inspect "" 1 "error: no such object: vault-app"

  run --separate-stderr instance_state app
  assert_success
  assert_equal "$stderr" ""

  instance_state app
  assert_equal "$INSTANCE_STATE" missing
}

@test "instance_state fails when the daemon is unreachable" {
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"

  run --separate-stderr instance_state app

  assert_failure 1
  assert_output ""
  assert_equal "$stderr" "$DAEMON_DOWN
vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
  assert_docker_not_called info
}

@test "instance_require_running passes when running" {
  docker_stub_set inspect true

  run --separate-stderr instance_require_running app

  assert_success
  assert_equal "$stderr" ""
}

@test "instance_require_running fails when stopped" {
  docker_stub_set inspect false

  run --separate-stderr instance_require_running app

  assert_failure 1
  assert_equal "$stderr" "vault: error: instance vault-app is not running"
}

@test "instance_require_running fails when missing" {
  docker_stub_set inspect "" 1 "$NO_SUCH"

  run --separate-stderr instance_require_running app

  assert_failure 1
  assert_equal "$stderr" "vault: error: instance vault-app is not running"
}

@test "instance_require_running fails when the daemon is unreachable" {
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"

  run --separate-stderr instance_require_running app

  assert_failure 1
  assert_equal "$stderr" "$DAEMON_DOWN
vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
}

@test "instance_tty_flags is empty without a TTY" {
  instance_tty_flags </dev/null >/dev/null

  assert_equal "${#INSTANCE_TTY_ARGS[@]}" 0
}

@test "instance_logs prints the bare driver without options" {
  run instance_logs json-file ""

  assert_success
  assert_output json-file
}

@test "instance_logs joins the options with a comma" {
  run instance_logs json-file "max-file=2 max-size=10m "

  assert_output "json-file max-file=2, max-size=10m"
}

@test "instance_logs masks token, password, secret and credential values" {
  run instance_logs splunk "splunk-token=a Splunk-Password=b aws-secret=c some-credential=d"

  assert_output "splunk splunk-token=***, Splunk-Password=***, aws-secret=***, some-credential=***"
}

@test "instance_logs leaves other values unchanged" {
  run instance_logs fluentd "max-size=10m tag={{.Name}} gelf-tls-key=/path"

  assert_output "fluentd max-size=10m, tag={{.Name}}, gelf-tls-key=/path"
}

# Runs instance_warn_stale_log_config with the running <driver> <opts> and the
# requested entries as the remaining arguments (no driver requested).
warn_stale() {
  CONFIG_LOG_DRIVER=""
  INSTANCE_LOG_DRIVER="$1"
  INSTANCE_LOG_OPTS="$2"
  shift 2
  CONFIG_LOG_OPTS=("$@")
  instance_warn_stale_log_config
}

@test "instance_warn_stale_log_config is silent when nothing is requested" {
  run --separate-stderr warn_stale json-file "max-size=1m "

  assert_success
  assert_equal "$stderr" ""
}

@test "instance_warn_stale_log_config is silent for the same set reordered" {
  run --separate-stderr warn_stale json-file "max-file=2 max-size=10m " max-size=10m max-file=2

  assert_success
  assert_equal "$stderr" ""
}

@test "instance_warn_stale_log_config is silent for a superset" {
  run --separate-stderr warn_stale json-file "max-file=3 max-size=10m " max-size=10m

  assert_equal "$stderr" ""
}

@test "instance_warn_stale_log_config warns for a differing value" {
  run --separate-stderr warn_stale json-file "max-size=1m " max-size=10m

  assert_success
  assert_equal "$stderr" "vault: warning: log configuration differs from the running instance (json-file max-size=1m); run 'vault down' then 'vault up' to apply them"
}

@test "instance_warn_stale_log_config warns for a missing key" {
  run --separate-stderr warn_stale json-file "" max-size=10m

  assert_success
  assert_equal "$stderr" "vault: warning: log configuration differs from the running instance (json-file); run 'vault down' then 'vault up' to apply them"
}

@test "instance_warn_stale_log_config masks sensitive values in the message" {
  run --separate-stderr warn_stale splunk "splunk-token=abc " splunk-token=xyz

  assert_success
  assert_equal "$stderr" "vault: warning: log configuration differs from the running instance (splunk splunk-token=***); run 'vault down' then 'vault up' to apply them"
}

# Like warn_stale, with a requested <driver> as the third argument.
warn_stale_driver() {
  INSTANCE_LOG_DRIVER="$1"
  INSTANCE_LOG_OPTS="$2"
  CONFIG_LOG_DRIVER="$3"
  shift 3
  CONFIG_LOG_OPTS=(${@+"$@"})
  instance_warn_stale_log_config
}

@test "instance_warn_stale_log_config warns when the driver differs" {
  run --separate-stderr warn_stale_driver journald "" local

  assert_success
  assert_equal "$stderr" "vault: warning: log configuration differs from the running instance (journald); run 'vault down' then 'vault up' to apply them"
}

@test "instance_warn_stale_log_config is silent when the driver matches" {
  run --separate-stderr warn_stale_driver local "" local

  assert_success
  assert_equal "$stderr" ""
}

@test "instance_warn_stale_log_config is silent when no driver is requested" {
  run --separate-stderr warn_stale journald ""

  assert_success
  assert_equal "$stderr" ""
}

@test "instance_warn_stale_log_config warns when the driver matches but an option is missing" {
  run --separate-stderr warn_stale_driver local "" local max-size=10m

  assert_success
  assert_equal "$stderr" "vault: warning: log configuration differs from the running instance (local); run 'vault down' then 'vault up' to apply them"
}
