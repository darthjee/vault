# Guardrails

Implement the guardrails of [cli-commands.md → Privilege model](../../../specs/cli-commands.md#privilege-model),
applied to the **merged** values (flags and `.vaultrc` alike).

- `cli/lib/guardrails.sh`:
  - `guardrails_check_volume <spec> <docker-host>`: the source is the text before the first
    `:` (handle a `~` source as given). Refused when its last path component is `docker.sock`,
    or it equals the path of a `unix://` `DOCKER_HOST` (passed in by `bin/vault`) →
    `refusing to mount the Docker socket (<src>)`, return 2;
  - `guardrails_check_port <spec>`: strips `/tcp` / `/udp`, takes the container side (the last
    `:`-field: `CONTAINER`, `HOST:CONTAINER`, `IP:HOST:CONTAINER`, including bracketed IPv6
    hosts), expands a `A-B` range, and refuses when it covers 2375 or 2376 →
    `refusing to publish the Docker daemon port <port>`, return 2;
  - `guardrails_check_all`: runs both over every merged volume and port.
- Named volumes (no `/` in the source) only trip the check when named exactly `docker.sock`.

## Files to Change
- `cli/lib/guardrails.sh` — new: socket and daemon-port guardrails.
- `test/cli/guardrails.bats` — new: `/var/run/docker.sock`, `/run/docker.sock`,
  `~/.docker/run/docker.sock`, `unix://` `DOCKER_HOST` path, non-socket paths pass; ports in
  every form (with protocol, IP, IPv6, ranges covering and not covering 2375/2376), host-side
  2375 allowed; message and exit 2.
