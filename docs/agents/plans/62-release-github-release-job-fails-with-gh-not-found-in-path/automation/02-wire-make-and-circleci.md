# Wire the make target and CircleCI step
Add a CI-only make target and call it from the `github-release` job, so the YAML only calls make targets.

- `Makefile`: add `ci-github-release-setup` to `.PHONY`, and a target next to `ci-release-setup`:

  ```make
  ci-github-release-setup:
  	scripts/ci/install_gh.sh
  ```

- `.circleci/config.yml`, job `github-release`: after `checkout`, add a step before "Create GitHub release and upload CLI assets":

  ```yaml
      - run:
          name: Install GitHub CLI
          command: make ci-github-release-setup
  ```

## Files to Change
- `Makefile` — new `ci-github-release-setup` target and `.PHONY` entry.
- `.circleci/config.yml` — "Install GitHub CLI" step in the `github-release` job.
