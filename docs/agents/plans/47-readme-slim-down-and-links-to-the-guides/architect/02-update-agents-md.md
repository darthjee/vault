# Update AGENTS.md
- **Privileges rule** (around line 70): reword per open point 5. The README keeps a short
  Security section that summarizes the risks of `--privileged` and links to
  `docs/guides/vault/security.md`, which holds the full explanation (host escape, device
  access, no seccomp/AppArmor, unusable on most managed platforms). Both must stay.
- **CLI section** (around line 78): "user docs: the README `## CLI` section" becomes
  "user docs: [docs/guides/vault/cli.md](docs/guides/vault/cli.md)".
- **Documentation section:** add a row or a short paragraph for `docs/guides/`: portable user
  guides (`vault.md` plus `vault/*.md`), copied whole into consumer repos; relative links stay
  inside the tree and everything else uses absolute URLs; the `**Vault version:**` line is kept
  in sync by `bump-version` / `check-version-tag`; checked by `make test-docs`; owner
  `product-owner`. Add the rule that a user-visible behaviour change updates the matching guide
  page.

## Files to Change
- `AGENTS.md`: Privileges rule, CLI user-docs pointer, `docs/guides/` entry.
