# Add the test-cli-e2e Make target
Add `test-cli-e2e: build-image` with the recipe `scripts/test_cli_e2e.sh`, next to `test-image`, and
add `test-cli-e2e` to `.PHONY`. `build-image` already depends on `bundle-cli`, so the image and
`build/vault` are both fresh. `IMAGE` and `SMOKE_TIMEOUT` are already exported.

## Files to Change
- `Makefile` — new `test-cli-e2e` target; `.PHONY` entry.
