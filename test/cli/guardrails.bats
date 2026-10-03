#!/usr/bin/env bats
# Tests for cli/lib/guardrails.sh (Docker socket and daemon port).
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
  # shellcheck source=SCRIPTDIR/../../cli/lib/config.sh
  source "$ROOT/cli/lib/config.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/guardrails.sh
  source "$ROOT/cli/lib/guardrails.sh"
}

check_volume_refused() {
  run --separate-stderr guardrails_check_volume "$1" "${2:-}"

  assert_failure 2
  assert_output ""
  assert_equal "$stderr" "vault: error: refusing to mount the Docker socket (${1%%:*})"
}

check_port_refused() {
  run --separate-stderr guardrails_check_port "$1"

  assert_failure 2
  assert_output ""
  assert_equal "$stderr" "vault: error: refusing to publish the Docker daemon port $2"
}

@test "volumes from docker.sock are refused" {
  check_volume_refused /var/run/docker.sock:/var/run/docker.sock
  check_volume_refused /run/docker.sock:/s
  # shellcheck disable=SC2088 # a literal ~ source, as given in .vaultrc
  check_volume_refused "~/.docker/run/docker.sock:/s"
  check_volume_refused ./docker.sock:/s:ro
  check_volume_refused /var/run/docker.sock/:/s
  check_volume_refused docker.sock:/s
  check_volume_refused /var/run/docker.sock
}

@test "the path of a unix:// DOCKER_HOST is refused" {
  check_volume_refused /home/me/.colima/default/sock:/s unix:///home/me/.colima/default/sock
  check_volume_refused /tmp/d.socket/:/s unix:///tmp/d.socket
}

@test "other volumes pass" {
  guardrails_check_volume /data:/data ""
  guardrails_check_volume /var/run/docker.sock.bak:/x ""
  guardrails_check_volume /var/run/docker.sock.d/x:/x ""
  guardrails_check_volume named:/data ""
  guardrails_check_volume /home/me/.colima/default/sock:/s tcp://host:2376
  guardrails_check_volume /tmp/other:/s unix:///tmp/d.socket
}

@test "a non-unix DOCKER_HOST is ignored" {
  guardrails_check_volume /tmp/x:/s tcp://tmp/x
  guardrails_check_volume /tmp/x:/s ""
}

@test "container ports 2375 and 2376 are refused in every form" {
  check_port_refused 2375 2375
  check_port_refused 2376 2376
  check_port_refused 8080:2375 2375
  check_port_refused 8080:2376/tcp 2376
  check_port_refused 2375/udp 2375
  check_port_refused 127.0.0.1:8080:2375 2375
  check_port_refused 127.0.0.1::2376 2376
  check_port_refused "[::1]:8080:2375/tcp" 2375
  check_port_refused 02375 2375
}

@test "container ranges covering 2375 or 2376 are refused" {
  check_port_refused 2370-2380 2375
  check_port_refused 2376-2380 2376
  check_port_refused 2300-2375 2375
  check_port_refused 8000-8010:2370-2380/tcp 2375
  check_port_refused 0.0.0.0:8000-8001:2375-2376 2375
}

@test "other ports pass, including 2375 on the host side" {
  guardrails_check_port 3000:80
  guardrails_check_port 2375:80
  guardrails_check_port 127.0.0.1:2376:80/udp
  guardrails_check_port 2377
  guardrails_check_port 2374
  guardrails_check_port 2377-2380
  guardrails_check_port 2370-2374
  guardrails_check_port "[::1]:2375:8080"
  guardrails_check_port 23750
}

@test "guardrails_check_all checks merged .vaultrc and flag values" {
  args_parse up
  config_parse /proj <<'EOF'
volume=/data:/data
volume=/var/run/docker.sock:/var/run/docker.sock
EOF
  config_merge 1.0.0

  run --separate-stderr guardrails_check_all ""

  assert_failure 2
  assert_equal "$stderr" "vault: error: refusing to mount the Docker socket (/var/run/docker.sock)"
}

@test "guardrails_check_all refuses a daemon port from a flag" {
  args_parse up -p 1:2 -p 2376
  config_reset
  config_merge 1.0.0

  run --separate-stderr guardrails_check_all ""

  assert_failure 2
  assert_equal "$stderr" "vault: error: refusing to publish the Docker daemon port 2376"
}

@test "guardrails_check_all uses DOCKER_HOST" {
  args_parse up -v /s/d.sock:/x
  config_reset
  config_merge 1.0.0

  run --separate-stderr guardrails_check_all unix:///s/d.sock

  assert_failure 2
  assert_equal "$stderr" "vault: error: refusing to mount the Docker socket (/s/d.sock)"
}

@test "guardrails_check_all passes the defaults and no volumes" {
  args_parse up
  config_reset
  config_merge 1.0.0

  run --separate-stderr guardrails_check_all ""

  assert_success
  assert_equal "$stderr" ""
}
