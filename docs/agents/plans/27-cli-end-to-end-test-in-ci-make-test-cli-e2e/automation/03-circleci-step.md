# Run it in CircleCI build-and-test
In `.circleci/config.yml`, add a step to the `build-and-test` job right after
`Build image and run smoke test`:

```yaml
      - run:
          name: Run CLI end-to-end test
          command: make test-cli-e2e
```

The job stays on the `machine` executor, with no new job and no context. The release workflow reuses
`build-and-test`, so tagged releases get the e2e check as well.

## Files to Change
- `.circleci/config.yml` — new step in `build-and-test`.
