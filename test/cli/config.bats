#!/usr/bin/env bats
# Tests for cli/lib/config.sh (.vaultrc, precedence and .vault.env).
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

  RC="$BATS_TEST_TMPDIR/vaultrc"
}

# Writes the given text, verbatim, to $RC.
write_rc() {
  printf '%s' "$1" >"$RC"
}

# Runs config_parse /proj on $RC and asserts an error (exit 1) with the
# given stderr.
check_rc_error() {
  run --separate-stderr config_parse /proj <"$RC"

  assert_failure 1
  assert_output ""
  assert_equal "$stderr" "$1"
}

@test "parses every key; comments and blank lines are skipped" {
  config_parse /proj <<'EOF'
# .vaultrc
name=my-app

image=darthjee/vault:0.2.0

runtime=sysbox
port=3000:80
port=3443:443
volume=/data/shared:/shared
env=RAILS_ENV=production
env-file=/etc/app.env
stop-timeout=30
EOF

  assert_equal "$CONFIG_RC_NAME" my-app
  assert_equal "$CONFIG_RC_NAME_SET" 1
  assert_equal "$CONFIG_RC_IMAGE" darthjee/vault:0.2.0
  assert_equal "$CONFIG_RC_RUNTIME" sysbox
  assert_equal "$CONFIG_RC_STOP_TIMEOUT" 30
  assert_equal "${#CONFIG_RC_PORTS[@]}" 2
  assert_equal "${CONFIG_RC_PORTS[0]}" 3000:80
  assert_equal "${CONFIG_RC_PORTS[1]}" 3443:443
  assert_equal "${CONFIG_RC_VOLUMES[0]}" /data/shared:/shared
  assert_equal "${CONFIG_RC_ENVS[0]}" RAILS_ENV=production
  assert_equal "${CONFIG_RC_ENV_FILES[0]}" /etc/app.env
}

@test "whitespace-only lines are blank" {
  write_rc $'  \n\t\nname=app\n'
  config_parse /proj <"$RC"

  assert_equal "$CONFIG_RC_NAME" app
}

@test "an empty input sets nothing" {
  config_parse /proj </dev/null

  assert_equal "$CONFIG_RC_NAME_SET" 0
  assert_equal "$CONFIG_RC_IMAGE_SET" 0
  assert_equal "$CONFIG_RC_RUNTIME_SET" 0
  assert_equal "$CONFIG_RC_STOP_TIMEOUT_SET" 0
  assert_equal "${#CONFIG_RC_PORTS[@]}" 0
  assert_equal "${#CONFIG_RC_VOLUMES[@]}" 0
  assert_equal "${#CONFIG_RC_ENVS[@]}" 0
  assert_equal "${#CONFIG_RC_ENV_FILES[@]}" 0
}

@test "values are verbatim: later =, spaces, no trimming, no expansion" {
  write_rc $'env=A=b=c\nenv= SPACED value \nenv=$HOME `x` "q"\nvolume=/a b/c:/d e\n'
  config_parse /proj <"$RC"

  assert_equal "${CONFIG_RC_ENVS[0]}" "A=b=c"
  assert_equal "${CONFIG_RC_ENVS[1]}" " SPACED value "
  assert_equal "${CONFIG_RC_ENVS[2]}" "\$HOME \`x\` \"q\""
  assert_equal "${CONFIG_RC_VOLUMES[0]}" "/a b/c:/d e"
}

@test "the last line without a trailing newline is read" {
  write_rc 'port=1:2
port=3:4'
  config_parse /proj <"$RC"

  assert_equal "${#CONFIG_RC_PORTS[@]}" 2
  assert_equal "${CONFIG_RC_PORTS[1]}" 3:4
}

@test "CRLF line endings are left verbatim in values" {
  write_rc $'port=1:2\r\nenv=A=1\r\n'
  config_parse /proj <"$RC"

  assert_equal "${CONFIG_RC_PORTS[0]}" $'1:2\r'
  assert_equal "${CONFIG_RC_ENVS[0]}" $'A=1\r'
}

@test "# starts a comment only at the start of a line" {
  write_rc 'env=A=1 # not a comment
'
  config_parse /proj <"$RC"

  assert_equal "${CONFIG_RC_ENVS[0]}" "A=1 # not a comment"
}

@test "an indented # line without = is malformed" {
  write_rc 'name=a
  # indented
'
  check_rc_error "vault: error: .vaultrc:2: expected key=value"
}

@test "a scalar given twice: the last line wins" {
  write_rc 'name=first
image=a:1
runtime=auto
stop-timeout=10
name=second
image=b:2
runtime=privileged
stop-timeout=20
'
  config_parse /proj <"$RC"

  assert_equal "$CONFIG_RC_NAME" second
  assert_equal "$CONFIG_RC_IMAGE" b:2
  assert_equal "$CONFIG_RC_RUNTIME" privileged
  assert_equal "$CONFIG_RC_STOP_TIMEOUT" 20
}

@test "an unknown key warns with its line and is skipped" {
  write_rc '# c
color=blue
name=app
'
  run --separate-stderr config_parse /proj <"$RC"

  assert_success
  assert_equal "$stderr" "vault: warning: .vaultrc:2: unknown key 'color'"

  config_parse /proj <"$RC" 2>/dev/null
  assert_equal "$CONFIG_RC_NAME" app
}

@test "keys are lowercase only" {
  write_rc 'Name=app
'
  run --separate-stderr config_parse /proj <"$RC"

  assert_success
  assert_equal "$stderr" "vault: warning: .vaultrc:1: unknown key 'Name'"
}

@test "a line without = fails naming the line (exit 1)" {
  write_rc 'name=app

just text
'
  check_rc_error "vault: error: .vaultrc:3: expected key=value"
}

@test "an invalid name fails naming the line (exit 1)" {
  write_rc 'name=My App
'
  check_rc_error "vault: error: .vaultrc:1: invalid value for name: 'My App'"
}

@test "an invalid runtime fails naming the line (exit 1)" {
  write_rc '
runtime=foo
'
  check_rc_error "vault: error: .vaultrc:2: invalid value for runtime: 'foo'"
}

@test "a non-positive stop-timeout fails naming the line (exit 1)" {
  write_rc 'stop-timeout=0
'
  check_rc_error "vault: error: .vaultrc:1: invalid value for stop-timeout: '0'"
}

@test "an empty image, port, volume or env-file fails (exit 1)" {
  local key
  for key in image port volume env-file; do
    write_rc "$key=
"
    check_rc_error "vault: error: .vaultrc:1: invalid value for $key: ''"
  done
}

@test "env values are never validated nor echoed" {
  write_rc 'env=
env=not a valid KEY at all
'
  run --separate-stderr config_parse /proj <"$RC"

  assert_success
  assert_equal "$stderr" ""
}

@test "relative volume sources resolve against the .vaultrc directory" {
  write_rc 'volume=./data:/data
volume=.:/src:ro
volume=sub/dir:/sub
volume=../up:/up
volume=named:/named
volume=/abs:/abs
volume=/anon
'
  config_parse /proj <"$RC"

  assert_equal "${CONFIG_RC_VOLUMES[0]}" /proj/data:/data
  assert_equal "${CONFIG_RC_VOLUMES[1]}" /proj:/src:ro
  assert_equal "${CONFIG_RC_VOLUMES[2]}" /proj/sub/dir:/sub
  assert_equal "${CONFIG_RC_VOLUMES[3]}" /proj/../up:/up
  assert_equal "${CONFIG_RC_VOLUMES[4]}" named:/named
  assert_equal "${CONFIG_RC_VOLUMES[5]}" /abs:/abs
  assert_equal "${CONFIG_RC_VOLUMES[6]}" /anon
}

@test "relative env-file paths resolve against the .vaultrc directory" {
  write_rc 'env-file=.env.prod
env-file=./conf/app.env
env-file=/etc/abs.env
'
  config_parse "/my proj/" <"$RC"

  assert_equal "${CONFIG_RC_ENV_FILES[0]}" "/my proj/.env.prod"
  assert_equal "${CONFIG_RC_ENV_FILES[1]}" "/my proj/conf/app.env"
  assert_equal "${CONFIG_RC_ENV_FILES[2]}" /etc/abs.env
}

@test "merge: defaults when neither flags nor .vaultrc give a value" {
  args_parse up
  config_reset
  config_merge 1.2.3

  assert_equal "$CONFIG_NAME" ""
  assert_equal "$CONFIG_IMAGE" darthjee/vault:1.2.3
  assert_equal "$CONFIG_RUNTIME" auto
  assert_equal "$CONFIG_STOP_TIMEOUT" 60
  assert_equal "${#CONFIG_PORTS[@]}" 1
  assert_equal "${CONFIG_PORTS[0]}" 3000:80
  assert_equal "${#CONFIG_VOLUMES[@]}" 0
  assert_equal "${#CONFIG_ENVS[@]}" 0
  assert_equal "${#CONFIG_ENV_FILES[@]}" 0
}

@test "merge: .vaultrc wins over the defaults" {
  args_parse up
  config_parse /proj <<'EOF'
name=rc
image=rc:1
runtime=privileged
stop-timeout=5
port=1:2
volume=/a:/b
env=A=1
env-file=/f
EOF
  config_merge 1.2.3

  assert_equal "$CONFIG_NAME" rc
  assert_equal "$CONFIG_IMAGE" rc:1
  assert_equal "$CONFIG_RUNTIME" privileged
  assert_equal "$CONFIG_STOP_TIMEOUT" 5
  assert_equal "${CONFIG_PORTS[*]}" 1:2
  assert_equal "${CONFIG_VOLUMES[*]}" /a:/b
  assert_equal "${CONFIG_ENVS[*]}" A=1
  assert_equal "${CONFIG_ENV_FILES[*]}" /f
}

@test "merge: flags win over .vaultrc, lists replaced per key" {
  args_parse up --name flag --image flag:1 --runtime sysbox --stop-timeout 9 -p 8:9 -e B=2
  config_parse /proj <<'EOF'
name=rc
image=rc:1
runtime=privileged
stop-timeout=5
port=1:2
port=3:4
volume=/a:/b
env=A=1
env-file=/f
EOF
  config_merge 1.2.3

  assert_equal "$CONFIG_NAME" flag
  assert_equal "$CONFIG_IMAGE" flag:1
  assert_equal "$CONFIG_RUNTIME" sysbox
  assert_equal "$CONFIG_STOP_TIMEOUT" 9
  assert_equal "${#CONFIG_PORTS[@]}" 1
  assert_equal "${CONFIG_PORTS[0]}" 8:9
  assert_equal "${CONFIG_VOLUMES[*]}" /a:/b
  assert_equal "${#CONFIG_ENVS[@]}" 1
  assert_equal "${CONFIG_ENVS[0]}" B=2
  assert_equal "${CONFIG_ENV_FILES[*]}" /f
}

@test "merge: -v and --env-file flags replace the .vaultrc entries" {
  args_parse up -v "/x y:/z" --env-file g
  config_parse /proj <<'EOF'
volume=/a:/b
env-file=/f
EOF
  config_merge 1.2.3

  assert_equal "${#CONFIG_VOLUMES[@]}" 1
  assert_equal "${CONFIG_VOLUMES[0]}" "/x y:/z"
  assert_equal "${#CONFIG_ENV_FILES[@]}" 1
  assert_equal "${CONFIG_ENV_FILES[0]}" g
}

@test "merge: a .vaultrc port replaces the 3000:80 default" {
  args_parse up
  config_parse /proj <<'EOF'
port=8080:80
EOF
  config_merge 1.2.3

  assert_equal "${#CONFIG_PORTS[@]}" 1
  assert_equal "${CONFIG_PORTS[0]}" 8080:80
}

@test ".vault.env goes before every env file, and a flag does not replace it (edge case 12)" {
  args_parse up --env-file a.env --env-file b.env
  config_reset
  config_merge 1.2.3
  config_vault_env /proj 1

  assert_equal "${#CONFIG_ENV_FILES[@]}" 3
  assert_equal "${CONFIG_ENV_FILES[0]}" /proj/.vault.env
  assert_equal "${CONFIG_ENV_FILES[1]}" a.env
  assert_equal "${CONFIG_ENV_FILES[2]}" b.env
}

@test ".vault.env goes before the .vaultrc env files" {
  args_parse up
  config_parse /proj <<'EOF'
env-file=x.env
EOF
  config_merge 1.2.3
  config_vault_env /proj/ 1

  assert_equal "${CONFIG_ENV_FILES[0]}" /proj/.vault.env
  assert_equal "${CONFIG_ENV_FILES[1]}" /proj/x.env
}

@test "a missing .vault.env adds nothing" {
  args_parse up
  config_reset
  config_merge 1.2.3
  config_vault_env /proj 0

  assert_equal "${#CONFIG_ENV_FILES[@]}" 0
}

@test ".vault.env alone is the only env file" {
  args_parse up
  config_reset
  config_merge 1.2.3
  config_vault_env /proj 1

  assert_equal "${#CONFIG_ENV_FILES[@]}" 1
  assert_equal "${CONFIG_ENV_FILES[0]}" /proj/.vault.env
}
