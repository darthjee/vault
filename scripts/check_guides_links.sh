#!/usr/bin/env bash
# Usage: scripts/check_guides_links.sh [ROOT [BOUND]]
# Checks the links of every *.md file under ROOT (default: docs/guides under
# the repository root). BOUND (default: ROOT) is the tree relative links may
# reach; ROOT must be BOUND itself or inside it. With no BOUND the guides
# stay portable once copied. Rules:
#   - relative links resolve against the linking file and must point to an
#     existing file or directory inside BOUND, anchors included (same page
#     "#anchor" or other page "cli.md#vaultrc"); anchors are checked for
#     every .md target inside BOUND, pages outside ROOT being parsed on demand;
#   - every other link must be an absolute https:// URL (http:, file:,
#     mailto:, absolute paths, ... fail);
#   - reference-style definitions ("[ref]: target") and image links
#     ("![alt](...)") are not allowed.
# Anchor slugs follow GitHub (lowercase, punctuation except "-" and "_"
# dropped, spaces to "-", duplicates get -1, -2, ... suffixes). Links inside
# fenced code blocks and inline code are ignored.
# Prints one "<file>: <message>: <link>" line per problem on stderr (<file>
# relative to ROOT, messages such as "missing file", "missing anchor" or
# "relative link leaves the bound") and exits 1, otherwise prints
# "test-docs: OK (<n> file(s))". An empty or missing ROOT passes; a ROOT
# outside BOUND fails with "test-docs: ROOT must be inside BOUND".
# Runs on bash 3.2 (macOS) with POSIX awk.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scan_root="${1:-$repo_root/docs/guides}"
bound="${2:-}"

if [ ! -d "$scan_root" ]; then
  echo "test-docs: OK (0 file(s))"
  exit 0
fi

scan_root="$(cd "$scan_root" && pwd)"

if [ -z "$bound" ]; then
  bound="$scan_root"
elif [ -d "$bound" ]; then
  bound="$(cd "$bound" && pwd)"
else
  echo "test-docs: BOUND is not a directory: $bound" >&2
  exit 1
fi

# Path of ROOT relative to BOUND, with a trailing "/" (empty when equal).
if [ "$scan_root" = "$bound" ]; then
  root_prefix=""
elif [ "$bound" = "/" ]; then
  root_prefix="${scan_root#/}/"
elif [[ "$scan_root" == "$bound"/* ]]; then
  root_prefix="${scan_root#"$bound"/}/"
else
  echo "test-docs: ROOT must be inside BOUND" >&2
  exit 1
fi

files=()
while IFS= read -r file; do
  files+=("${file#./}")
done < <(cd "$scan_root" && find . -type f -name '*.md' | sort)

if [ "${#files[@]}" -eq 0 ]; then
  echo "test-docs: OK (0 file(s))"
  exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# Parses a markdown file and prints, tab-separated:
#   H <slug>          for every heading (GitHub slug, duplicates suffixed);
#   L LINK <target>   for every inline link [text](target);
#   L IMG <target>    for every image link ![alt](target);
#   L REF <target>    for every reference definition [ref]: target.
# Fenced code blocks and inline code spans are skipped.
# Usage: parse_markdown FILE
parse_markdown() {
  awk '
    function slugify(text,    slug, n) {
      # [text](url) in a heading keeps only its text.
      while (match(text, /\[[^]]*\]\([^)]*\)/)) {
        inner = substr(text, RSTART + 1, RLENGTH - 1)
        sub(/\]\(.*$/, "", inner)
        text = substr(text, 1, RSTART - 1) inner substr(text, RSTART + RLENGTH)
      }
      slug = tolower(text)
      gsub(/[^a-z0-9 _-]/, "", slug)
      gsub(/ /, "-", slug)
      n = seen[slug]++
      if (n > 0) slug = slug "-" n
      return slug
    }

    function target_of(raw,    t) {
      t = raw
      sub(/^[ \t]+/, "", t)
      if (substr(t, 1, 1) == "<") {
        t = substr(t, 2)
        sub(/>.*$/, "", t)
        return t
      }
      sub(/[ \t].*$/, "", t)
      return t
    }

    {
      line = $0

      if (fence != "") {
        if (index(line, fence) > 0 && line ~ /^ ? ? ?(```|~~~)/) {
          stripped = line
          sub(/^ */, "", stripped)
          if (substr(stripped, 1, 3) == fence) fence = ""
        }
        next
      }
      if (line ~ /^ ? ? ?(```|~~~)/) {
        stripped = line
        sub(/^ */, "", stripped)
        fence = substr(stripped, 1, 3)
        next
      }

      if (line ~ /^ ? ? ?#+([ \t]|$)/) {
        text = line
        sub(/^ *#+[ \t]*/, "", text)
        sub(/[ \t]+#+[ \t]*$/, "", text)
        sub(/[ \t]+$/, "", text)
        if (match(line, /#+/) && RLENGTH <= 6) {
          printf "H\t%s\n", slugify(text)
        }
      }

      gsub(/``[^`]+``/, "", line)
      gsub(/`[^`]*`/, "", line)

      if (line ~ /^ ? ? ?\[[^]]+\]:([ \t]|$)/) {
        rest = line
        sub(/^ *\[[^]]+\]:/, "", rest)
        printf "L\tREF\t%s\n", target_of(rest)
        next
      }

      while (match(line, /!?\[[^]]*\]\([^)]*\)/)) {
        link = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        kind = "LINK"
        if (substr(link, 1, 1) == "!") kind = "IMG"
        sub(/^!?\[[^]]*\]\(/, "", link)
        sub(/\)$/, "", link)
        printf "L\t%s\t%s\n", kind, target_of(link)
      }
    }
  ' "$1"
}

# Parses a markdown file inside BOUND into $work_dir/<path>.parsed and
# $work_dir/<path>.slugs, keyed by its path relative to BOUND.
# Usage: index_file PATH
index_file() {
  mkdir -p "$work_dir/$(dirname "$1")"
  parse_markdown "$bound/$1" > "$work_dir/$1.parsed"
  { grep '^H	' "$work_dir/$1.parsed" || true; } | cut -f 2 > "$work_dir/$1.slugs"
}

for file in "${files[@]}"; do
  index_file "$root_prefix$file"
done

errors=0

# Usage: report FILE MESSAGE LINK
report() {
  echo "$1: $2: $3" >&2
  errors=$((errors + 1))
}

# Resolves "." and ".." of a path relative to BOUND, textually (no
# realpath -m). Prints the normalised path, or fails when it leaves BOUND.
# Usage: normalise PATH
normalise() {
  local rest="$1/"
  local result="" part

  while [ -n "$rest" ]; do
    part="${rest%%/*}"
    rest="${rest#*/}"
    case "$part" in
      "" | ".") ;;
      "..")
        if [ -z "$result" ]; then
          return 1
        fi
        case "$result" in
          */*) result="${result%/*}" ;;
          *) result="" ;;
        esac
        ;;
      *)
        if [ -z "$result" ]; then
          result="$part"
        else
          result="$result/$part"
        fi
        ;;
    esac
  done
  printf '%s\n' "$result"
}

# Checks one link of a page under ROOT (FILE is relative to ROOT).
# Usage: check_link FILE KIND TARGET
check_link() {
  local file="$1" kind="$2" target="$3"
  local path anchor dir resolved

  case "$kind" in
    IMG)
      report "$file" "image links are not allowed" "$target"
      return
      ;;
    REF)
      report "$file" "reference-style links are not allowed" "$target"
      return
      ;;
  esac

  if [[ "$target" == https://?* ]]; then
    return
  fi
  if [ -z "$target" ] || [[ "$target" == /* ]] || [[ "$target" =~ ^[A-Za-z][A-Za-z0-9+.-]*: ]]; then
    report "$file" "link must be relative or absolute https://" "$target"
    return
  fi

  path="${target%%#*}"
  anchor=""
  if [ "$path" != "$target" ]; then
    anchor="${target#*#}"
  fi
  path="${path%%\?*}"

  if [ -z "$path" ]; then
    resolved="$root_prefix$file"
  else
    dir="$(dirname "$file")"
    if [ "$dir" = "." ]; then
      dir=""
    else
      dir="$dir/"
    fi
    if ! resolved="$(normalise "$root_prefix$dir$path")"; then
      report "$file" "relative link leaves the bound" "$target"
      return
    fi
    if [ -n "$resolved" ] && [ ! -e "$bound/$resolved" ]; then
      report "$file" "missing file" "$target"
      return
    fi
  fi

  if [ -z "$anchor" ] || [[ "$resolved" != *.md ]] || [ ! -f "$bound/$resolved" ]; then
    return
  fi
  if [ ! -f "$work_dir/$resolved.slugs" ]; then
    index_file "$resolved"
  fi
  if ! grep -qxF -- "$anchor" "$work_dir/$resolved.slugs"; then
    report "$file" "missing anchor" "$target"
  fi
}

for file in "${files[@]}"; do
  while IFS="	" read -r _ kind target; do
    check_link "$file" "$kind" "$target"
  done < <(grep '^L	' "$work_dir/$root_prefix$file.parsed" || true)
done

if [ "$errors" -gt 0 ]; then
  exit 1
fi

echo "test-docs: OK (${#files[@]} file(s))"
