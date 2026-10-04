# Install, platforms and completion
Create `docs/guides/vault/cli.md` with the page header (one-line purpose, link back to
`../vault.md`) and the sections that cover getting the CLI onto a machine:

- **Install:** the `curl -fsSL https://raw.githubusercontent.com/darthjee/vault/.../install.sh | bash`
  one-liner with an absolute URL (copy the exact URL from the README); pinning `VAULT_VERSION`;
  every installer variable (`VAULT_INSTALL_DIR` and the rest, with defaults, from `install.sh`);
  adding the install dir to `PATH`.
- **Download and verify:** manual download plus the `SHA256SUMS` check.
- **Shell completion:** bash (`~/.bashrc`) and zsh (`~/.zshrc`, before `compinit`).
- **Supported platforms:** Linux and macOS, bash 3.2+; Windows not supported. Link
  `security.md` for supported runtimes.

## Files to Change
- `docs/guides/vault/cli.md` — new page: header, Install, Download and verify, Shell completion,
  Supported platforms.
