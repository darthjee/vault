ARG DOCKER_VERSION=29.8.2
FROM docker:${DOCKER_VERSION}-dind

# Cache-bust for the apk layer: a new value (monthly by default, YYYY-MM, computed by
# scripts/release.sh / make build-image) rebuilds this layer and every later one, so bash
# security fixes are picked up. The default keeps a plain `docker build` working.
ARG APK_REFRESH=unset
RUN echo "apk refresh: ${APK_REFRESH}" && apk add --no-cache bash

# Created first: COPY --chmod would also apply 644 to the directories it creates.
RUN mkdir -p -m 0755 /usr/local/share/vault /usr/local/share/vault/completion
COPY --chmod=644 cli/completion/vault.bash cli/completion/_vault /usr/local/share/vault/completion/
COPY source/lib/ /usr/local/lib/vault/
COPY --chmod=755 source/bin/entrypoint.sh /usr/local/bin/vault-entrypoint
COPY --chmod=755 source/bin/install.sh /usr/local/bin/vault-install
COPY --chmod=755 build/vault /usr/local/bin/vault

ENV DOCKER_TLS_CERTDIR=""

VOLUME /var/lib/docker
WORKDIR /vault
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/vault-entrypoint"]
