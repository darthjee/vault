SHELLCHECK_IMAGE ?= koalaman/shellcheck:v0.11.0
BATS_IMAGE ?= bats/bats:1.14.0
IMAGE ?= darthjee/vault:dev

export SHELLCHECK_IMAGE BATS_IMAGE

.PHONY: lint test bump-version check-version-tag build-image test-image update-description release

lint:
	scripts/lint.sh

test:
	scripts/test.sh

bump-version:
	$(if $(VERSION),scripts/bump_version.sh $(VERSION),$(error VERSION is required, e.g. make bump-version VERSION=X.Y.Z))

check-version-tag:
	$(if $(TAG),scripts/check_tag_version.sh $(TAG),$(error TAG is required, e.g. make check-version-tag TAG=X.Y.Z))

build-image:
	docker build $(if $(DOCKER_VERSION),--build-arg DOCKER_VERSION=$(DOCKER_VERSION)) -t $(IMAGE) .

test-image:
	@echo "test-image: not implemented yet (see issue #7)"

update-description:
	@echo "update-description: not implemented yet (see issue #9)"

release:
	$(if $(TAG),@echo "release $(TAG): not implemented yet (see issue #9)",$(error TAG is required, e.g. make release TAG=X.Y.Z))
