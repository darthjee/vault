# shellcheck shell=bash disable=SC2034 # CONTAINER_ARGS is read by callers
# Library: the `docker run` argument list of `vault up` and `vault run`.
# Sourcing this file only defines functions.

# Builds the full `docker run` argument list (starting with "run") into
# CONTAINER_ARGS, from the resolved values:
#   RUNTIME_ARG (runtime_select), CONFIG_STOP_TIMEOUT, CONFIG_VOLUMES,
#   CONFIG_PORTS, CONFIG_ENV_FILES (.vault.env first), CONFIG_ENVS,
#   CONFIG_IMAGE (config_merge) and, for run, ARGS_PASSTHROUGH.
# Usage: container_build_args <up|run> <name> <mount-dir> <attach 0|1>
#   mount-dir: the absolute dir mounted on /vault; "" for no /vault mount
#   (--image without [dir])
# Order:
#   run
#   <runtime> --stop-timeout <n>
#   [-v <dir>:/vault] -v vault-<name>-data:/var/lib/docker
#   -v <extra>... -p <port>...
#   --env-file <file>... -e <env>...
#   up: --name vault-<name> [-d unless attached] | run: --rm
#   <image> [run: <compose args>...]
container_build_args() {
  local command="$1" name="$2" mount_dir="$3" attach="$4" item

  CONTAINER_ARGS=(run "$RUNTIME_ARG" --stop-timeout "$CONFIG_STOP_TIMEOUT")

  if [ -n "$mount_dir" ]; then
    CONTAINER_ARGS+=(-v "$mount_dir:/vault")
  fi
  CONTAINER_ARGS+=(-v "$(naming_volume "$name"):/var/lib/docker")

  for item in ${CONFIG_VOLUMES[@]+"${CONFIG_VOLUMES[@]}"}; do
    CONTAINER_ARGS+=(-v "$item")
  done
  for item in ${CONFIG_PORTS[@]+"${CONFIG_PORTS[@]}"}; do
    CONTAINER_ARGS+=(-p "$item")
  done
  for item in ${CONFIG_ENV_FILES[@]+"${CONFIG_ENV_FILES[@]}"}; do
    CONTAINER_ARGS+=(--env-file "$item")
  done
  for item in ${CONFIG_ENVS[@]+"${CONFIG_ENVS[@]}"}; do
    CONTAINER_ARGS+=(-e "$item")
  done

  case "$command" in
    up)
      CONTAINER_ARGS+=(--name "$(naming_container "$name")")
      if [ "$attach" != 1 ]; then
        CONTAINER_ARGS+=(-d)
      fi
      CONTAINER_ARGS+=("$CONFIG_IMAGE")
      ;;
    run)
      CONTAINER_ARGS+=(--rm "$CONFIG_IMAGE")
      CONTAINER_ARGS+=(${ARGS_PASSTHROUGH[@]+"${ARGS_PASSTHROUGH[@]}"})
      ;;
  esac
  return 0
}
