# Dockerfile

Create `./Dockerfile` per image.md → Dockerfile / Base image:

```dockerfile
ARG DOCKER_VERSION=29.8.2
FROM docker:${DOCKER_VERSION}-dind
RUN apk add --no-cache bash
COPY source/lib/ /usr/local/lib/vault/
COPY source/bin/entrypoint.sh /usr/local/bin/vault-entrypoint
ENV DOCKER_TLS_CERTDIR=""
VOLUME /var/lib/docker
WORKDIR /vault
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/vault-entrypoint"]
```

- Make sure `vault-entrypoint` is executable (commit `source/bin/entrypoint.sh` with mode 755, or `COPY --chmod=755`).
- Use exec-form `ENTRYPOINT` and no `CMD`, so `docker run vault <args>` passes the args to the entrypoint (used by #6).

## Files to Change
- `Dockerfile` — new.
