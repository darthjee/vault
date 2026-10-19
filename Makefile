SHELLCHECK_IMAGE ?= koalaman/shellcheck:v0.11.0
BATS_IMAGE ?= bats/bats:1.14.0
BASH32_TEST_IMAGE ?= vault-bash32-test:local
ZSH_IMAGE ?= zshusers/zsh:5.9
IMAGE ?= darthjee/vault:dev
SMOKE_TIMEOUT ?= 120
RELEASE_IMAGE ?= darthjee/vault
PUSH ?= true
# Monthly cache-bust for the apk layer (UTC year-month).
APK_REFRESH ?= $(shell date -u +%Y-%m)
# docker-container buildx builder (pinned BuildKit) shared by build-image and
# the release jobs. The default `docker` driver on the classic image store
# ignores rewrite-timestamp, so reproducible builds need this builder.
BUILDER ?= vault-builder
BUILDKIT_IMAGE ?= moby/buildkit:v0.33.1
# Registry layer cache written by the release (scripts/release.sh). build-image
# imports it anonymously (the repository is public) and never exports it.
# Set it empty (BUILD_CACHE=) to disable the import.
BUILD_CACHE ?= darthjee/vault:buildcache
# Literal comma, for use inside $(if ...) arguments.
comma := ,

export SHELLCHECK_IMAGE BATS_IMAGE BASH32_TEST_IMAGE ZSH_IMAGE IMAGE SMOKE_TIMEOUT RELEASE_IMAGE PUSH BUILDER BUILDKIT_IMAGE BUILD_CACHE

.PHONY: lint test test-docs bundle-cli bump-version check-version-tag buildx-builder build-image test-image test-cli-e2e update-description release github-release require-tag ci-release-setup ci-github-release-setup

lint:
	scripts/lint.sh

test:
	scripts/test.sh

test-docs:
	scripts/check_guides_links.sh
	scripts/check_guides_links.sh docs/agents .

bundle-cli:
	scripts/bundle_cli.sh

bump-version:
	$(if $(VERSION),scripts/bump_version.sh $(VERSION),$(error VERSION is required, e.g. make bump-version VERSION=X.Y.Z))

check-version-tag:
	$(if $(TAG),scripts/check_tag_version.sh $(TAG),$(error TAG is required, e.g. make check-version-tag TAG=X.Y.Z))

# Creates the $(BUILDER) docker-container builder when it does not exist yet.
buildx-builder:
	@docker buildx inspect $(BUILDER) >/dev/null 2>&1 || \
		docker buildx create --name $(BUILDER) --driver docker-container \
			--driver-opt image=$(BUILDKIT_IMAGE)

# Reproducible build: fixed SOURCE_DATE_EPOCH (default 0, env override) and
# rewrite-timestamp=true, so layer digests depend only on content. The image
# is still loaded into the local store as $(IMAGE) (type=docker output).
build-image: bundle-cli buildx-builder
	SOURCE_DATE_EPOCH=$${SOURCE_DATE_EPOCH:-0} docker buildx build --builder $(BUILDER) \
		--output type=docker,rewrite-timestamp=true \
		$(if $(BUILD_CACHE),--cache-from type=registry$(comma)ref=$(BUILD_CACHE)) \
		$(if $(DOCKER_VERSION),--build-arg DOCKER_VERSION=$(DOCKER_VERSION)) \
		--build-arg APK_REFRESH=$(APK_REFRESH) \
		-t $(IMAGE) .

test-image: build-image
	scripts/test_image.sh

test-cli-e2e: build-image
	scripts/test_cli_e2e.sh

update-description:
	scripts/ci/update_description.sh

# require-tag is listed before bundle-cli so a missing TAG fails before any build work.
release: require-tag bundle-cli
	$(if $(APK_REFRESH),APK_REFRESH=$(APK_REFRESH)) scripts/release.sh $(TAG)

# require-tag first so a missing TAG fails before any build work.
# The script builds the CLI bundle itself.
github-release: require-tag
	scripts/github_release.sh $(TAG)

require-tag:
	$(if $(TAG),@true,$(error TAG is required, e.g. make $(or $(firstword $(MAKECMDGOALS)),release) TAG=X.Y.Z))

ci-release-setup:
	scripts/ci/setup_buildx.sh
	scripts/ci/docker_login.sh

ci-github-release-setup:
	scripts/ci/install_gh.sh
