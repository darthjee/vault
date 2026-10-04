# Run bundle-cli before every image build
The Dockerfile now copies `build/vault`, so every target that builds the image must build the
bundle first ([cli-tooling.md → Make targets](../../../specs/cli-tooling.md#make-targets-and-scripts)):

- `build-image: bundle-cli` (so `test-image`, which depends on `build-image`, gets it too);
- `release: bundle-cli`, keeping the existing `TAG` guard.

Make sure `.dockerignore` does not exclude `build/` (it is empty today; leave it so, or list
exclusions that keep `build/vault`). `build/` stays git-ignored.

## Files to Change
- `Makefile` — add `bundle-cli` as a prerequisite of `build-image` and `release`.
