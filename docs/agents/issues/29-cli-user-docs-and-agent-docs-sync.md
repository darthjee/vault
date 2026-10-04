# Issue: CLI user docs and agent docs sync

## Description
Part of epic #20 (Vault CLI). It depends on every previous sub-issue of #20 (#21–#28, all
closed). Agents:
- `product-owner`: README and agent docs;
- `automation`: `DOCKERHUB_DESCRIPTION.md`.

Documentation only: no code, script, Makefile or CI changes.

## Problem
The README only partly describes the CLI (an Install section added by #26, still carrying
"(#28)" placeholders), and has no CLI usage section. The Docker Hub description doesn't mention
the CLI. `AGENTS.md` still lists the CLI under "Future work", and `flow.md` /
`architecture.md` / `folder-structure.md` only partly reflect what epic #20 built.
The spec's own Future work list (`cli-overview.md`) has to be kept somewhere before #30
deletes the spec.

## Expected Behavior
- The **README** gets a full CLI section (epic #39 later moves it into `docs/guides/`; #29
  does not shorten it for that) covering:
  - install (`curl | bash`, release asset, pinning `VAULT_VERSION`, the download-and-verify
    alternative with `SHA256SUMS`); the "(#28)" placeholders are removed now that the
    release assets exist;
  - commands (`up`, `down`, `logs`, `status`, `compose`, `run`, `install`,
    `version`, `help`) and instance naming (`vault-<name>`, `vault-<name>-data`);
  - runtime selection and the `--privileged` fallback warning, linking to **Security**, and
    how to force a mode (`--runtime=sysbox|privileged`);
  - ports (default `3000:80`), env vars, `.vault.env`, `.vaultrc`, extra mounts,
    `--image` for baked images;
  - Docker Desktop shared paths (`[dir]` and `-v` sources must be shared; documented, not
    checked);
  - two instances must not share a data volume;
  - shell completion;
  - the supported platforms (Linux and macOS; not Windows).
- **`DOCKERHUB_DESCRIPTION.md`** mentions the CLI and how to install it.
- **Agent docs:**
  - `AGENTS.md` moves the CLI out of "Future work" into the design, and the agents table
    includes `cli`;
  - `AGENTS.md` → Future work takes over the still-relevant items of the spec's Future work
    list (`vault up --wait`, Homebrew tap, Windows, `vault build`/`pack`, self-update /
    uninstall, `vault ls`, remote Docker hosts, coloured output; Sysbox in CI is already listed);
  - `docs/agents/folder-structure.md`, `architecture.md` and `flow.md` match what was
    actually built (`cli/`, `install.sh`, `build/`, the new scripts, Make targets and CI job).
  - `flow.md` gets a **CLI flow** section: what `vault up` does (args / `.vaultrc` / `.vault.env`
    → runtime detection → `docker run`), `down`, `run` / `compose`, and the install path
    (`install.sh` → image install entry → copied CLI and completions).
- The spec under `docs/agents/specs/` is **not** removed here: #30, the next and last
  sub-issue, removes it. References to the spec (e.g. "specs override these docs") stay
  until #30. The spec's own open points are not updated here.
