# bash 3.2 test image: runs the CLI bats suites on bash 3.2 (macOS default
# bash), so bash 4+ features cannot creep in. Built by scripts/test.sh as
# $BASH32_TEST_IMAGE. Same entrypoint and library layout as bats/bats.
FROM bash:3.2

# bats-core matches BATS_IMAGE (bats/bats:1.14.0).
ARG BATS_CORE_VERSION=v1.14.0
ARG BATS_SUPPORT_VERSION=v0.3.0
ARG BATS_ASSERT_VERSION=v2.1.0

ENV BATS_LIB_PATH=/usr/lib/bats

RUN set -eu; \
    apk add --no-cache ncurses; \
    tmp="$(mktemp -d)"; \
    cd "$tmp"; \
    wget -qO- "https://github.com/bats-core/bats-core/archive/refs/tags/${BATS_CORE_VERSION}.tar.gz" | tar -xz; \
    bash bats-core-*/install.sh /usr/local; \
    mkdir -p "$BATS_LIB_PATH/bats-support" "$BATS_LIB_PATH/bats-assert"; \
    wget -qO- "https://github.com/bats-core/bats-support/archive/refs/tags/${BATS_SUPPORT_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C "$BATS_LIB_PATH/bats-support"; \
    wget -qO- "https://github.com/bats-core/bats-assert/archive/refs/tags/${BATS_ASSERT_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C "$BATS_LIB_PATH/bats-assert"; \
    cd /; \
    rm -rf "$tmp"

WORKDIR /code

ENTRYPOINT ["bats"]
