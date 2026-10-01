# Product-owner Plan: Docker image: compose run, signal handling and exit code

Main plan: [plan.md](plan.md)

## Shared contracts

The decisions in the plan.md table, specifically:

- Signal before compose started → stop dockerd if started, exit `128 + signal` (143 for SIGTERM, 130 for SIGINT).
- `docker compose down` failing during shutdown → warning on stderr, dockerd still stopped, exit code stays compose's.

## Implementation Steps

### Step 1 — Record the #6 decisions in the image spec
In `docs/agents/specs/docker-image/image.md`:

- **Exit codes and messages**: replace the "Signal before compose started | #6 decides and records it here" row with `128 + signal` (143 for SIGTERM, 130 for SIGINT), no message. Add a row: "`compose down` fails during shutdown | compose's exit code | warning on stderr". Update the closing sentence ("The remaining values are left to #6") so it no longer says anything is undecided.
- **Edge cases** row 7: add the exit code (`128 + signal`) to the behaviour.
- Optionally note under the entrypoint-flow table that compose runs in the background and the entrypoint `wait`s for it, so a trap fires at once. Bash defers traps while a foreground child runs.

## Files to Change
- `docs/agents/specs/docker-image/image.md` — fill in the open exit-code row and add the `compose down` failure decision.

## Notes
- Do not touch `README.md` or `docs/agents/flow.md` / `architecture.md`; reconciling those docs belongs to #10.
