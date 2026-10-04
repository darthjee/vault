# Guides Spec: README split

Part of the [guides spec](guides-overview.md). Fixes which README sections move to the guides
and what the README keeps. Applied by #47, after every page exists, so no content disappears
from the README before its replacement lands.

## Sections that move

| README section | Destination |
|----------------|-------------|
| `## CLI` (and every subsection: Install, Commands, Instances, Runtime, Options and configuration, Baked images, Docker Desktop) | `vault/cli.md` |
| `## Usage` → `### Running`, `### Arguments` | `vault/docker-run.md` |
| `## Usage` → `### Shipping a stack as its own image`, `### Offline preload` | `vault/base-image.md` |
| `## Usage` → `### Ports`, `### Bind mounts` | `vault/concepts.md` |
| `## Usage` → `### Persistence` | `vault/concepts.md` (model), `vault/operations.md` (data volume use) |
| `## Environment variables` | `vault/configuration.md` |
| `## Behaviour` (exit code, service failures, shutdown, shared `/var/lib/docker`) | `vault/operations.md`, exit codes also in `vault/troubleshooting.md` |
| `## Behaviour` → startup errors | `vault/troubleshooting.md` |
| `## Supported runtimes and platforms` | `vault/security.md` |
| `## Security` | `vault/security.md` |

## What the README keeps

- Title, badges and the overview (with the port-flow diagram).
- The `**Current Version:**` line.
- A short quick start (one `docker run`, one `vault up`), using `darthjee/vault` and said so.
- A link to `docs/guides/vault.md` for detailed usage.
- A short Security summary linking to `docs/guides/vault/security.md`. `AGENTS.md` →
  Privileges requires the README to keep a Security section; #47 keeps or adjusts that rule
  (see [open point 5](guides-overview.md#open-points)).
- `## Development` and `## License` (contributor material stays).

## Links to update

Updated by #47 in the same PR as the README change.

| File | Link | Owner |
|------|------|-------|
| `DOCKERHUB_DESCRIPTION.md` | `https://github.com/darthjee/vault#cli`, `https://github.com/darthjee/vault#security` → the matching guide pages (absolute URLs). | `automation` |
| `AGENTS.md` | "user docs: the README `## CLI` section" → `docs/guides/vault/cli.md`; Privileges rule. | `architect` |
| `docs/agents/*` | Any reference to the moved README sections. | `product-owner` |
