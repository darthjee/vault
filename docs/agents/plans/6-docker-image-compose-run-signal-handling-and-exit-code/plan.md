# Plan: Docker image: compose run, signal handling and exit code

Issue: [6-docker-image-compose-run-signal-handling-and-exit-code.md](../../issues/6-docker-image-compose-run-signal-handling-and-exit-code.md)

## Overview
This replaces the entrypoint placeholder left by #5. The entrypoint now runs `docker compose` in the background from `/vault`, waits for it, and traps SIGTERM / SIGINT to run the shutdown sequence (`compose down`, then stop dockerd). It exits with compose's exit code, or with `128 + signal` if no compose was running. `dev` implements the two new libraries, the entrypoint wiring and the bats tests. `product-owner` records the two decisions made while refining #6 in the spec.

## Agents involved

- [dev](dev.md)
- [product-owner](product-owner.md)

## Shared contracts

Behaviour that both the code and the spec (`docs/agents/specs/docker-image/image.md`) must describe the same way:

| Situation | Behaviour | Exit code |
|-----------|-----------|-----------|
| Compose exits on its own (`up` or passthrough) | Stop dockerd only; no `compose down` | compose's exit code |
| SIGTERM / SIGINT while compose runs | `docker compose down`, stop dockerd and wait for it | compose's exit code (0 on a clean `docker stop`) |
| SIGTERM / SIGINT before compose started | Stop dockerd if it was started | `128 + signal`: 143 (TERM), 130 (INT) |
| Second signal during shutdown | Ignored | — |
| `docker compose down` fails during shutdown | Warning on stderr; dockerd is still stopped | compose's exit code (unchanged) |

`COMPOSE_UP_ARGS` is split with `read -ra` and has no quoting support. The README note about this belongs to #10, not to this issue.
