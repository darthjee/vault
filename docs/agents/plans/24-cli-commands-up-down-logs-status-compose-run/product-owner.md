# Product-owner Plan: CLI commands: up, down, logs, status, compose, run

Main plan: [plan.md](plan.md)

## Shared contracts

Record contracts 1–5 of [plan.md](plan.md#shared-contracts) in the spec, word for word:
the instance-state classification, the `run` refusal message, the TTY flags and where they go,
the status layout as kept, and the `docker run` failure attribution (including the 125/126/127
rule).

## Implementation Steps

### Step 1 — Mark open points 2–6 settled in `cli-overview.md`
In the Open points table, set "Settled by" to `#24 (settled)` for rows 2–6. Replace each
proposed default with the decision taken (2: refuse, exit 1; 3: `-i`/`-t` for `run` **and**
`compose`; 4: layout kept; 5: classification via `docker inspect`'s "No such object";
6: port strings → port hint, other failures under sysbox-runc → Sysbox hint, only for exit
codes 125–127 on passthrough commands).

### Step 2 — Update `cli-commands.md`
- Container arguments: slot 9 for `run` becomes `[-i] [-t] --rm`, and the "`-i` / `-t` are not
  added yet" line becomes the TTY rule.
- Commands table: `run` refuses a running instance. `compose` adds `-i`/`-t` the same way.
- Status output: drop "draft that #24 may adjust" and say the layout is fixed.
- Messages table: add the `run`-while-running row.
- Diagnostics: describe how a missing instance is told apart from an unreachable daemon.
- Edge cases: add a row for `run` while running (#24).

## Files to Change
- `docs/agents/specs/cli-overview.md` — open points 2–6 marked settled with the decisions.
- `docs/agents/specs/cli-commands.md` — TTY flags, `run` refusal, fixed status layout, new
  message row, instance-state classification.

## Notes
- If `cli`'s implementation has to change wording (for example a message), the spec follows
  the code in the same PR, as `cli.md` requires.
