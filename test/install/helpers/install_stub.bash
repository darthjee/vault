# shellcheck shell=bash
# Test helper: makes the stub docker (test/cli/helpers/docker_stub.bash) act
# like the image's vault-install entry. Load docker_stub first, then call
# install_stub_setup after docker_stub_setup.
#
# A successful `docker run` (the scripted "run" status is 0) writes, into the
# host side of its `-v <dir>:/install` argument: vault (0755) and
# completion/vault.bash, completion/_vault (0644). Each file holds one line
# "<name> $INSTALL_STUB_MARK" (default "stub"), so tests can tell runs apart.

# Wraps the stub docker so `docker run` stages the install files.
install_stub_setup() {
  mv "$DOCKER_STUB_BIN/docker" "$DOCKER_STUB_BIN/docker-base"
  cat >"$DOCKER_STUB_BIN/docker" <<STUB
#!$(command -v bash)
"\${0%/*}/docker-base" "\$@" || exit \$?
[ "\${1:-}" = run ] || exit 0
dir=""
while [ "\$#" -gt 0 ]; do
  if [ "\$1" = -v ] && [ "\$#" -gt 1 ]; then
    case "\$2" in
      *:/install) dir="\${2%:/install}" ;;
    esac
  fi
  shift
done
[ -n "\$dir" ] || exit 0
mark="\${INSTALL_STUB_MARK:-stub}"
mkdir -p "\$dir/completion"
printf 'vault %s\\n' "\$mark" >"\$dir/vault"
printf 'vault.bash %s\\n' "\$mark" >"\$dir/completion/vault.bash"
printf '_vault %s\\n' "\$mark" >"\$dir/completion/_vault"
chmod 0755 "\$dir/vault"
chmod 0644 "\$dir/completion/vault.bash" "\$dir/completion/_vault"
STUB
  chmod 0755 "$DOCKER_STUB_BIN/docker"
}

# Prints the staging dir of the recorded `docker run` call (the host side of
# its "<dir>:/install" volume).
install_stub_staging() {
  local line field
  while IFS= read -r line || [ -n "$line" ]; do
    [ "${line%%	*}" = run ] || continue
    while [ -n "$line" ]; do
      field="${line%%	*}"
      case "$field" in
        *:/install) printf '%s\n' "${field%:/install}" ;;
      esac
      [ "$field" != "$line" ] || break
      line="${line#*	}"
    done
  done <"$DOCKER_STUB_LOG"
}
