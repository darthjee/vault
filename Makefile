SHELLCHECK_IMAGE ?= koalaman/shellcheck:v0.11.0
BATS_IMAGE ?= bats/bats:1.14.0
BASH32_TEST_IMAGE ?= vault-bash32-test:local
ZSH_IMAGE ?= zshusers/zsh:5.9
IMAGE ?= darthjee/vault:dev
SMOKE_TIMEOUT ?= 120
RELEASE_IMAGE ?= darthjee/vault
PUSH ?= true

export SHELLCHECK_IMAGE BATS_IMAGE BASH32_TEST_IMAGE ZSH_IMAGE IMAGE SMOKE_TIMEOUT RELEASE_IMAGE PUSH

.PHONY: lint test test-docs bundle-cli bump-version check-version-tag build-image test-image test-cli-e2e update-description release github-release require-tag ci-release-setup

lint:
	scripts/lint.sh

test:
	scripts/test.sh

test-docs:
	scripts/check_guides_links.sh

bundle-cli:
	scripts/bundle_cli.sh

bump-version:
	$(if $(VERSION),scripts/bump_version.sh $(VERSION),$(error VERSION is required, e.g. make bump-version VERSION=X.Y.Z))

check-version-tag:
	$(if $(TAG),scripts/check_tag_version.sh $(TAG),$(error TAG is required, e.g. make check-version-tag TAG=X.Y.Z))

build-image: bundle-cli
	docker build $(if $(DOCKER_VERSION),--build-arg DOCKER_VERSION=$(DOCKER_VERSION)) -t $(IMAGE) .

test-image: build-image
	scripts/test_image.sh

test-cli-e2e: build-image
	scripts/test_cli_e2e.sh

update-description:
	scripts/ci/update_description.sh

# require-tag is listed before bundle-cli so a missing TAG fails before any build work.
release: require-tag bundle-cli
	scripts/release.sh $(TAG)

# require-tag first so a missing TAG fails before any build work.
# The script builds the CLI bundle itself.
github-release: require-tag
	scripts/github_release.sh $(TAG)

require-tag:
	$(if $(TAG),@true,$(error TAG is required, e.g. make $(or $(firstword $(MAKECMDGOALS)),release) TAG=X.Y.Z))

ci-release-setup:
	scripts/ci/setup_buildx.sh
	scripts/ci/docker_login.sh
