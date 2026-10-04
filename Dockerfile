ARG DOCKER_VERSION=29.8.2
FROM docker:${DOCKER_VERSION}-dind

RUN apk add --no-cache bash

COPY source/lib/ /usr/local/lib/vault/
COPY --chmod=755 source/bin/entrypoint.sh /usr/local/bin/vault-entrypoint
COPY --chmod=755 build/vault /usr/local/bin/vault
COPY --chmod=755 source/bin/install.sh /usr/local/bin/vault-install
# Created first: COPY --chmod would also apply 644 to the directories it creates.
RUN mkdir -p -m 0755 /usr/local/share/vault /usr/local/share/vault/completion
COPY --chmod=644 cli/completion/vault.bash cli/completion/_vault /usr/local/share/vault/completion/

ENV DOCKER_TLS_CERTDIR=""

VOLUME /var/lib/docker
WORKDIR /vault
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/vault-entrypoint"]
