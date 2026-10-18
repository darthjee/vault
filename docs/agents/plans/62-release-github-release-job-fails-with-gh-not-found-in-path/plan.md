# Plan: Release: github-release job fails with "gh not found in PATH"

Issue: [62-release-github-release-job-fails-with-gh-not-found-in-path.md](../../issues/62-release-github-release-job-fails-with-gh-not-found-in-path.md)

## Overview
Install the GitHub CLI from GitHub's official apt repository in the CircleCI `github-release` job, through a new CI-only script and make target, so `scripts/github_release.sh` finds `gh`.

See [automation.md](automation.md) for the full plan.
