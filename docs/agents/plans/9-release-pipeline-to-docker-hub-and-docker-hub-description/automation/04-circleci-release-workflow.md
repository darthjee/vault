# CircleCI release workflow
In `.circleci/config.yml`, keep the YAML thin: executors, contexts and filters, with every `run` calling a make target.

- Add a reusable `machine` executor (`image: ubuntu-2404:current`). Use it in the existing `build-and-test` job too, without changing what that job does.
- New jobs:
  - `check-version-tag`: `checkout`, then `make check-version-tag TAG=$CIRCLE_TAG`.
  - `build-and-release`: `checkout`, `make ci-release-setup`, then `make release TAG=$CIRCLE_TAG`.
  - `update-description`: `checkout`, then `make update-description`.
- Add a `release` workflow. Every job in it uses the tag filter `tags: only: /^[0-9]+\.[0-9]+\.[0-9]+$/` with `branches: ignore: /.*/`, defined once as a YAML anchor:
  - `check-version-tag`;
  - `build-and-test`, reusing the existing job;
  - `build-and-release`, which requires both jobs above and uses `context: docker-hub`;
  - `update-description`, which requires `build-and-release` and uses `context: docker-hub`.
- Leave the existing `build-and-test` workflow unchanged. It has no filters, so it never runs on tags, and it has no context.
- Validate with `circleci config validate`.

## Files to Change
- `.circleci/config.yml` — shared executor, the three new jobs and the tag-only `release` workflow.
