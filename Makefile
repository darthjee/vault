SHELLCHECK_IMAGE ?= koalaman/shellcheck:v0.11.0
BATS_IMAGE ?= bats/bats:1.14.0
BASH32_TEST_IMAGE ?= vault-bash32-test:local
IMAGE ?= darthjee/vault:dev
SMOKE_TIMEOUT ?= 120
RELEASE_IMAGE ?= darthjee/vault
PUSH ?= true

export SHELLCHECK_IMAGE BATS_IMAGE BASH32_TEST_IMAGE IMAGE SMOKE_TIMEOUT RELEASE_IMAGE PUSH

.PHONY: lint test bundle-cli bump-version check-version-tag build-image test-image update-description release ci-release-setup

lint:
	scripts/lint.sh

test:
	scripts/test.sh

bundle-cli:
	scripts/bundle_cli.sh

bump-version:
	$(if $(VERSION),scripts/bump_version.sh $(VERSION),$(error VERSION is required, e.g. make bump-version VERSION=X.Y.Z))

check-version-tag:
	$(if $(TAG),scripts/check_tag_version.sh $(TAG),$(error TAG is required, e.g. make check-version-tag TAG=X.Y.Z))

build-image:
	docker build $(if $(DOCKER_VERSION),--build-arg DOCKER_VERSION=$(DOCKER_VERSION)) -t $(IMAGE) .

test-image: build-image
	scripts/test_image.sh

update-description:
	scripts/ci/update_description.sh

release:
	$(if $(TAG),scripts/release.sh $(TAG),$(error TAG is required, e.g. make release TAG=X.Y.Z))

ci-release-setup:
	scripts/ci/setup_buildx.sh
	scripts/ci/docker_login.sh
