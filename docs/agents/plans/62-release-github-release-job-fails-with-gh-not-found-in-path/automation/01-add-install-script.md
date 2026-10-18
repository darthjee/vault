# Add the install script
Create `scripts/ci/install_gh.sh`, executable, in the style of `scripts/ci/setup_buildx.sh` (usage header comment, `set -euo pipefail`, `ROOT`/`cd`, `install-gh:`-prefixed log lines):

1. If `command -v gh` succeeds, print `install-gh: gh already installed` plus `gh --version` and exit 0.
2. Otherwise follow GitHub's official Debian/Ubuntu instructions (cli.github.com):
   - `sudo mkdir -p -m 755 /etc/apt/keyrings`
   - download `https://cli.github.com/packages/githubcli-archive-keyring.gpg` (`curl -fsSL` or `wget -qO-`) into `/etc/apt/keyrings/githubcli-archive-keyring.gpg` via `sudo tee`, and `sudo chmod go+r` it;
   - write `deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main` to `/etc/apt/sources.list.d/github-cli.list`;
   - `sudo apt-get update` and `sudo apt-get install -y gh`.
3. Print `gh --version`.

CI-only: document that in the header, like the other `scripts/ci/` scripts.

## Files to Change
- `scripts/ci/install_gh.sh` — new script (mode 755).
