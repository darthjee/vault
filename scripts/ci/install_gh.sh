#!/usr/bin/env bash
# Usage: scripts/ci/install_gh.sh
# CI-only. Installs the GitHub CLI (gh) from the official cli.github.com
# apt repository (GitHub's Debian/Ubuntu instructions), so
# `make github-release` can run on the ubuntu-2404 machine image, which
# does not ship gh. No-op when gh is already installed. Needs sudo/apt.
# gh is not pinned: apt installs the latest stable release.
set -euo pipefail

KEYRING="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
KEYRING_URL="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/github-cli.list"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if command -v gh >/dev/null 2>&1; then
  echo "install-gh: gh already installed"
  gh --version
  exit 0
fi

echo "install-gh: adding the cli.github.com apt repository"
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "$KEYRING_URL" | sudo tee "$KEYRING" >/dev/null
sudo chmod go+r "$KEYRING"
echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://cli.github.com/packages stable main" \
  | sudo tee "$SOURCES_LIST" >/dev/null

echo "install-gh: installing gh"
sudo apt-get update
sudo apt-get install -y gh

gh --version
