# Add the make target and CircleCI job

**Makefile:** add `github-release` to `.PHONY`, and add

```make
# require-tag first so a missing TAG fails before any build work.
github-release: require-tag
	scripts/github_release.sh $(TAG)
```

(The script runs `bundle_cli.sh` itself, so `bundle-cli` isn't a prerequisite. Adding it would also be fine.)

**.circleci/config.yml:** add a job:

```yaml
  github-release:
    executor: machine
    steps:
      - checkout
      - run:
          name: Create GitHub release and upload CLI assets
          command: make github-release TAG="$CIRCLE_TAG"
```

and in the `release` workflow:

```yaml
      - github-release:
          context: github
          requires:
            - build-and-release
          filters: *release-filters
```

The `github` context is attached to no other job.

## Files to Change
- `Makefile` — `github-release` target and `.PHONY` entry.
- `.circleci/config.yml` — `github-release` job and workflow entry.
