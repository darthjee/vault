# Add bundle-cli to CI
In the `build-and-test` job, add a `make bundle-cli` step after `make test` and before
`make test-image`, as in [cli-ci.md → PR pipeline](../../../specs/cli-ci.md#pr-pipeline).

## Files to Change
- `.circleci/config.yml` — new step in `build-and-test`.
