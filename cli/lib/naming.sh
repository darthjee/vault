# shellcheck shell=bash
# Library: instance naming (container vault-<name>, volume vault-<name>-data).
# Sourcing this file only defines functions.

# Resolves the instance name into NAMING_NAME.
# Usage: naming_resolve <explicit-name> <image-flag-given 0|1> <image> <dir-given 0|1> <dir>
#   explicit-name: --name, else .vaultrc name= (already validated); "" = none
#   image: the --image value (never .vaultrc image=)
#   dir: [dir], or the working directory when no [dir] was given
# Order: explicit name; else the image name when --image was given without
# [dir]; else the basename of dir. Derived names are sanitized.
# Returns 2 (with the "bad name" error and hint) when the result is empty.
naming_resolve() {
  local explicit="$1" image_given="$2" image="$3" dir_given="$4" dir="$5"
  local base

  NAMING_NAME=""
  if [ -n "$explicit" ]; then
    NAMING_NAME="$explicit"
    return 0
  fi

  if [ "$image_given" = 1 ] && [ "$dir_given" != 1 ]; then
    base="$(naming_from_image "$image")"
  else
    base="$(_naming_basename "$dir")"
  fi

  NAMING_NAME="$(naming_sanitize "$base")"
  if [ -z "$NAMING_NAME" ]; then
    output_error "cannot derive an instance name from '$base'"
    output_hint 'pass --name <name>'
    return 2
  fi
  return 0
}

# Prints the image name without registry, path, digest and tag.
# Usage: naming_from_image <image>
# e.g. registry.example.com:5000/team/my-app:1.0 -> my-app
naming_from_image() {
  local base="${1##*/}"
  base="${base%%@*}"
  base="${base%%:*}"
  printf '%s\n' "$base"
}

# Prints <base> lowercased, without any character outside [a-z0-9_.-].
# Usage: naming_sanitize <base>  (e.g. "My App!" -> myapp)
naming_sanitize() {
  printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -cd 'abcdefghijklmnopqrstuvwxyz0123456789_.-'
  printf '\n'
}

# Returns 0 when <name> matches [a-z0-9][a-z0-9_.-]*.
# Usage: naming_valid <name>
naming_valid() {
  args_valid_name "$1"
}

# Prints the container name: vault-<name>.
# Usage: naming_container <name>
naming_container() {
  printf 'vault-%s\n' "$1"
}

# Prints the data volume name: vault-<name>-data.
# Usage: naming_volume <name>
naming_volume() {
  printf 'vault-%s-data\n' "$1"
}

# Prints the last path component of <dir>, ignoring trailing slashes
# ("/" stays "/").
# Usage: _naming_basename <dir>
_naming_basename() {
  local dir="$1"
  while [ "${#dir}" -gt 1 ] && [ "${dir%/}" != "$dir" ]; do
    dir="${dir%/}"
  done
  if [ "$dir" = / ]; then
    printf '/\n'
    return 0
  fi
  printf '%s\n' "${dir##*/}"
}
