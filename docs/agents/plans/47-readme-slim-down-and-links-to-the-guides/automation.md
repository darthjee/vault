# Automation Plan: README slim-down and links to the guides

Main plan: [plan.md](plan.md)

## Shared contracts

- Guide URLs (absolute): base `https://github.com/darthjee/vault/blob/main/docs/guides/`.
  Index `vault.md`, CLI `vault/cli.md`, Security `vault/security.md`.
- README anchors `#cli` and `#security`: `#cli` is removed. `#security` stays, but it becomes a
  short summary, so the Docker Hub page should link to the guide instead.

## Implementation Steps

### Step 1 — Point the Docker Hub description at the guides
In `DOCKERHUB_DESCRIPTION.md`:
- Replace `https://github.com/darthjee/vault#cli` (around line 72) with the CLI guide URL.
- Replace the "Security section of the README" link (around line 88) with the Security guide
  URL, and reword the link text (for example "the security guide").
- Add one line pointing at the full user guides (index URL), in the section that introduces
  usage or near the top. Keep the page short: it is published to Docker Hub by
  `make update-description`.

## Files to Change
- `DOCKERHUB_DESCRIPTION.md`: links to the guides.

## CI Checks
- `make lint`, `make test` (CI job: `build-and-test`). `make update-description` only runs on
  release.

## Notes
- Use absolute URLs only. Docker Hub can't resolve relative links.
