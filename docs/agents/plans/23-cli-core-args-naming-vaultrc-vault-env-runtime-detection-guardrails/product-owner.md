# Product Owner Plan: CLI core: args, naming, .vaultrc, .vault.env, runtime detection, guardrails

Main plan: [plan.md](plan.md)

## Shared contracts

- **Open point 1 is settled** by #23: for `vault run`, the first positional argument is
  `[dir]` only when it names an existing directory; otherwise it is the first compose argument.
  `--` ends CLI options explicitly.
- The new library files: `docker.sh`, `args.sh`, `naming.sh`, `config.sh`, `guardrails.sh`,
  `runtime.sh`, `container.sh`.
- Any deviation `cli` reports in the PR is written into the spec in the same PR.

## Implementation Steps

### Step 1 — Record #23's decisions in the spec
- `docs/agents/specs/cli-overview.md`:
  - **Open points** table: mark point 1 as **Settled**, with the rule above (same style as
    point 7);
  - the `cli/lib/*.sh` row of the paths table: list the libraries #23 adds.
- `docs/agents/specs/cli-commands.md` → **Syntax**: state the `run` `[dir]` rule as decided,
  not as a proposal.
- `docs/agents/specs/cli-config.md`: note that the parser reads `.vaultrc` from stdin, fed by
  `bin/vault`, which keeps the "only `bin/vault` reads `.vaultrc`" rule.

### Step 2 — Fold in `cli`'s deviations
After `cli` finishes, update `cli-commands.md` / `cli-config.md` with any deviation it reports
(e.g. the final container argument order under **Container arguments**, and the removal of
the "may be refined by #23 / #24" sentence if the order is now fixed).

## Files to Change
- `docs/agents/specs/cli-overview.md` — open point 1 settled; library list.
- `docs/agents/specs/cli-commands.md` — `run` `[dir]` rule; container argument order if changed.
- `docs/agents/specs/cli-config.md` — stdin parsing note; any deviation.

## Notes
- Documentation only; no tests.
