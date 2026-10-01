ARG DOCKER_VERSION=29.8.2
FROM docker:${DOCKER_VERSION}-dind

RUN apk add --no-cache bash

COPY source/lib/ /usr/local/lib/vault/
COPY --chmod=755 source/bin/entrypoint.sh /usr/local/bin/vault-entrypoint

ENV DOCKER_TLS_CERTDIR=""

VOLUME /var/lib/docker
WORKDIR /vault
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/vault-entrypoint"]
