# Plan: CLI commands: up, down, logs, status, compose, run

Issue: [24-cli-commands-up-down-logs-status-compose-run.md](../../issues/24-cli-commands-up-down-logs-status-compose-run.md)

## Overview
Wire the six instance commands (`up`, `down`, `logs`, `status`, `compose`, `run`) into
`cli/bin/vault` on top of `vault_resolve` (#23), using the messages, exit codes and edge cases
already in `docs/agents/specs/cli-commands.md`. This issue also settles spec open points 2–6.
`cli` writes the code and tests. `product-owner` records the settled points in the spec.

## Agents involved

- [cli](cli.md)
- [product-owner](product-owner.md)

## Shared contracts

These decisions settle open points 2–6. `cli` implements them exactly. `product-owner` writes
them into the spec with the same wording.

1. **Instance state (open point 5).** One call,
   `docker inspect --format '{{.State.Running}}' vault-<name>`:
   - exit 0, `true` → `running`; exit 0, anything else → `stopped`;
   - non-zero exit, stderr containing `No such object` → `missing` (docker's stderr is not
     shown);
   - any other non-zero exit → docker's stderr passed through, then
     `error: cannot reach the Docker daemon` + `is Docker running, and can this user access it?`,
     exit 1.
   - Used by `up`, `down`, `logs`, `status`, `compose` and `run`. `down`, `logs`, `status` and
     `compose` still never call `docker info`.
2. **`run` while the instance is running (open point 2).** Checked after `vault_resolve`,
   before `docker run`. New message row:
   `error: instance vault-<name> is running` + hint `stop it with "vault down", or use "vault compose"`,
   exit 1. A stopped or missing instance does not block `run`.
3. **TTY flags (open point 3).** `-i` when stdin is a TTY (`[ -t 0 ]`), `-t` when stdout is a
   TTY (`[ -t 1 ]`), always in the order `-i` then `-t`.
   - `run`: inserted in container-argument slot 9, before `--rm`:
     `... -e <env>... [-i] [-t] --rm <image> <args>...`.
   - `compose`: `docker exec [-i] [-t] vault-<name> docker compose <args>...`.
   - `up` never adds them (`up -f` stays as today).
4. **Status layout (open point 4).** Kept exactly as drafted in `cli-commands.md` → Status
   output. Labels are padded to the width of `runtime:` plus one space. Multiple ports and env
   keys are joined with `, `.
5. **Failed `docker run` attribution (open point 6).** Applies to `up` (detached and `-f`, only
   when docker fails before the container starts) and `run`. On a non-zero `docker run` whose
   container did not start:
   - stderr contains `port is already allocated` or `address already in use` → port hint;
   - otherwise, under `--runtime=sysbox-runc` → `error: sysbox-runc failed to start the container` + hint;
   - otherwise (`--privileged`) → docker's error only, exit 1.
   - Docker's stderr is always passed through first.
   - For passthrough (`run`, `up -f`): docker's own start-failure exit codes are 125, 126 and 127.
     Only those are classified. Any other code is the inner command's exit code and is passed
     through unchanged.
