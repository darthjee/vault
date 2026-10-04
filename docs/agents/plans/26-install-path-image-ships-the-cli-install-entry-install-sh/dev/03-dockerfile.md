# Ship the CLI in the Dockerfile
After the existing `COPY` lines, add:

```dockerfile
COPY --chmod=755 build/vault /usr/local/bin/vault
COPY --chmod=755 source/bin/install.sh /usr/local/bin/vault-install
COPY --chmod=644 cli/completion/vault.bash cli/completion/_vault /usr/local/share/vault/completion/
```

`source/lib/install.sh` already reaches the image through the existing
`COPY source/lib/ /usr/local/lib/vault/`. Leave `ENTRYPOINT`, `ENV`, `VOLUME`, `WORKDIR` and
`EXPOSE` unchanged. Check that the existing `COPY source/lib/` keeps readable modes, because the
install entry runs as a non-root uid and must be able to read the library.

Check locally: `make bundle-cli && make build-image`, then
`docker run --rm --entrypoint vault darthjee/vault:dev version` prints `vault 0.0.1`, and
`docker run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install -v "$(mktemp -d):/install" darthjee/vault:dev`
exits 0.

## Files to Change
- `Dockerfile` — copy the bundle, the install entry and the completions.
