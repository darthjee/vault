# Issue: README slim-down and links to the guides

## Description
Part of epic #39 (portable user guides for Vault). Depends on every guide page sub-issue (#42–#46, all merged). Applies [`docs/agents/specs/guides-readme.md`](../specs/guides-readme.md).

Agents:
- `architect`: `README.md`, `AGENTS.md`, `.claude/agents/*.md`;
- `product-owner`: `docs/agents/*`, `docs/guides/*`;
- `automation`: `DOCKERHUB_DESCRIPTION.md`;
- `cli`: `cli/lib/runtime.sh` and its tests under `test/cli/`.

## Problem
Now that the guides exist under `docs/guides/`, the README duplicates their detailed usage sections, and nothing points readers or agents at `docs/guides/`. Several files link to README sections that are about to move:
- `DOCKERHUB_DESCRIPTION.md` (`#cli`, `#security`);
- `AGENTS.md` ("user docs: the README `## CLI` section" and the Privileges rule);
- `docs/agents/architecture.md` (README `## CLI`, README Security section);
- the CLI hint `see "Supported runtimes" in the README` (`cli/lib/runtime.sh`).

Two leftovers from #46 also need fixing:
- `.claude/agents/product-owner.md` still says `docs/guides/` "does not exist yet; #42 creates it".
- `docs/guides/vault/base-image.md` → "Offline preload" saves the inner image as `my-app` and then builds the baked image as `my-app` too, which overwrites it.

## Expected Behavior
- **README** keeps, per the spec: title, badges, the overview (with the port-flow diagram), the `**Current Version:**` line, a short quick start (one `docker run`, one `vault up`, using `darthjee/vault` and saying so), a link to `docs/guides/vault.md` for detailed usage, a short `## Security` summary, and `## Development` / `## License`. The Security summary mentions the supported runtimes (Sysbox preferred, `--privileged` fallback) and links to `docs/guides/vault/security.md`.
- **Moved out of the README** (their content is already in the guides): `## CLI` and all of its subsections, every `## Usage` subsection, `## Environment variables`, `## Behaviour`, `## Supported runtimes and platforms`, and the details of `## Security`.
- **CLI messages** (`cli`): the unsupported-runtime hint in `cli/lib/runtime.sh` becomes `see Security in the README`, and the assertions in `test/cli/runtime.bats` and `test/cli/resolve.bats` change to match. The `sysbox-runc not found … (see Security in the README)` warning stays as it is, because that section still exists.
- **`DOCKERHUB_DESCRIPTION.md`**: the `#cli` and `#security` links point at the matching guide pages (absolute `https://github.com/darthjee/vault/blob/main/docs/guides/...` URLs), plus a link to the guides index.
- **`AGENTS.md`**: the CLI user-docs pointer goes to `docs/guides/vault/cli.md`. The Privileges rule is reworded: the README keeps a short Security summary linking to `docs/guides/vault/security.md`, and that page holds the details (open point 5). Add a `docs/guides/` entry covering its purpose, the portability rules, `make test-docs` (link check) and the `**Vault version:**` line.
- **`.claude/agents/product-owner.md`**: drop the stale "does not exist yet; #42 creates it" remark.
- **`docs/agents/`**: `folder-structure.md` describes `docs/guides/`. `architecture.md` links to the guide pages instead of README sections. `contributing.md` says that a behaviour change also updates the guides.
- **`docs/guides/`**: in `vault/base-image.md` → "Offline preload", the inner app image is tagged `my-app:1.0` (as in `examples.md`), so building the baked image does not overwrite it. If `vault/cli.md` quotes the changed hint, update it.
- The spec under `docs/agents/specs/` is **not** removed here (#48 removes it).
- `make test-docs`, `make lint` and `make test` pass.
