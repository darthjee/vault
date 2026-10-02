#!/usr/bin/env bash
# Usage: DOCKER_HUB_USERNAME=... DOCKER_HUB_PASSWORD=... scripts/ci/docker_login.sh
# CI-only. Logs in to Docker Hub with credentials from the environment.
# The password is passed via stdin, never on the command line.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [ -z "${DOCKER_HUB_USERNAME:-}" ] || [ -z "${DOCKER_HUB_PASSWORD:-}" ]; then
  echo "docker-login: DOCKER_HUB_USERNAME and DOCKER_HUB_PASSWORD must be set" >&2
  exit 1
fi

printf '%s' "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
