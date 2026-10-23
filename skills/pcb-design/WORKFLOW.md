# The workflow: how an AI carries a board from idea to order on its own

`SKILL.md` lists the rules and points to the detail. This file describes the work itself: the loop an assistant runs for
hours without being walked through each step, what it writes down as it goes, where it stops and asks, and what it does
at a pause point so the next session or another model can pick the work up cold. It came out of a real project (a
wideband O2 controller extended with an analog output: two boards, firmware, simulation, about 30 routing runs in a
day) and every rule here is something that run needed `[reported: wideband carrier, 2026-10-23]`.

## The shape

```
 scaffold ──► requirements ──► parts ──► schematic ──► placement ──► routing ──► 3D/mech ──► fab files ──► audit ──► release ──► order
    │            (owner)                  (code)        (code)        (code)                   (checks)    (2nd model)  (gate)    (owner)
    └── STATE.md holds the stage, decisions, check results; every later session reads it first
```

Each stage has an exit condition in `STATE.md`, and **only doing the thing moves a stage**, not writing about it. Design
files are generated from code (`gen/*.py`), so every change is a diff, every run is repeatable, and KiCad stays open to
the owner (the drift check catches their edits before a regeneration would overwrite them).

## The loop inside a stage

The stages that take many tries (placement, routing, a simulation that won't settle) run this loop:

1. **Measure first.** Run the check that defines "done" for the stage and keep its raw output. For routing that is
   DRC against a baseline (only *new* violations count, plus every unconnected item) and a via-in-pad check. Make the
   measurement a script in `checks/` the first time you do it by hand. A procedure kept in prose gets redone slightly
   differently every time.
2. **One change per run.** Change one thing, regenerate, measure, and write a row in the attempt table:
   `run | change | result`. Keep the failures: they stop the next session repeating them.
3. **Read the tool's own output before blaming the problem.** The placer's printout showed parts dropped 16 mm from
   where they belonged. Five routing runs had blamed "congestion". Freerouting's per-pass log showed it counting the
   existing board's spacing as violations. When a fix makes things worse, the cause is upstream of the fix.
4. **Targeted change beats sweep, once runs are slow.** A seed sweep is cheap when a run takes 30 s and finds the lucky
   placement; at 4 min a run, ten seeds is 45 minutes for maybe one connection. Use sweeps to explore, then make the
   change that removes the cause.
5. **Escalate the method, not the effort.** Nearest-spot placement → placement by net length (annealing). One-at-a-time
   routing → negotiated routing (PathFinder). A pour island → a check that finds and joins pour pieces. When three
   variations of the same approach fail, the approach is the problem.
6. **A result that looks like a tool quirk can be a real defect.** "Zone to zone unconnected" was a ground pour piece
   holding the op-amp's ground pins and touching nothing else. Find out what an item is before dismissing it.

Commit at each real improvement (a lower count on the stage's own check), with the count in the message, so there is
always a known-good state to return to and a regression is one `git checkout` away.

## Autonomy: when to keep going and when to stop

The owner sets the pace once ("keep going"); after that the assistant works through the stage without stopping to report
each step or to ask questions that have a sensible default.

- **Keep going** through anything reversible: regeneration, runs, checks, commits on the project's branch, notes.
- **Default and record** an open design question rather than wait: put the question, the default chosen and why in
  `STATE.md` (and on the review page). The owner answers in a batch.
- **Stop and ask** before anything hard to reverse or outward-facing: spending money (orders, paid parts), deleting the
  owner's files, overwriting their KiCad edits, pushing to a repo they haven't said to push to, publishing.
- **Report when a real chunk is done or blocked**, leading with the stage's own measure: "0 new DRC violations, 1
  connection open", not "made good progress".
- When the owner asks how it's going mid-run, answer from the measurement you have, and say what's still running.

## The pause point: save the day

A pause point is the end of a long run of work: context running out, a natural stop, or the owner stepping away. At a
pause point, before anything else:

1. **Commit the best state** with its measure in the message.
2. **Replace `HANDOFF.md`** (next to `STATE.md`), don't append to it. It's the halfway tier between memory and the
   transcript, in this order:
   - verify-first commands with expected output
   - the one thing in progress
   - the attempt table
   - the **last raw output**: numbers and printout, not only your reading of them, which can be wrong
   - next steps in order
   - facts a cold session would re-derive
   - tool quirks
   - a do-not-re-raise list
   - open questions with their defaults

   Skip it when the session was short and `STATE.md` already says everything.
3. **Update `STATE.md`**: status line with the date, the stage's real position, what's not done.
4. **Write the lessons** to `LESSONS.md` (what went wrong, what caught it, whether it's general), and propose the general
   ones as lines for this skill. Fold them in once the owner agrees, in both the installed copy and the repo copy.
5. **Give the owner a resume block**: one fenced paste-back for a fresh session. It names the docs to read, what to
   verify, the current task and what not to re-raise.

## Audits by a second model

Before release, a different model (or a person) audits the design from a read-only pack (`audit_pack.py`): the design
files, the requirements, the check results, and the questions that matter most (power, the analog chain, anything that
drives a heater or a motor). Findings come back as input to verify, never as fact, and each round is recorded in
`AUDIT.md`. The release gate refuses while a BLOCKER or BUG is open. Write `AGENTS.md` for any model, so the same repo
works for Claude, Codex or a person.

## The tools that carry it (in `scripts/`)

| Script | Role in the loop |
| --- | --- |
| `run_all.py` + `checks.json` | Every check at once; writes the checks table in `STATE.md` |
| `drc_vs_baseline.py` | DRC minus a baseline board's own violations (extending an existing board), plus unconnected items |
| `via_in_pad.py` | Vias whose drill lands in an SMD pad (DRC doesn't flag this) |
| `finish_routes.py` | Grid router for what the autorouter leaves, and negotiated routing (PathFinder) for a dense group of nets before it runs |
| `drift.py` | Owner's KiCad edits since the last generation |
| `release.py` | The money gate |
| `audit_pack.py` | Read-only pack and prompt for the second model |

## Worked example

[`flyboy-byte/wideband-work`](https://github.com/flyboy-byte/wideband-work) (branch `analog-out`): a fork of the rusEFI
wideband controller with an added 0-5 V output. It has `STATE.md`, `HANDOFF.md` with the run history, `LESSONS.md`,
the generators, the checks, the SPICE decks and `AGENTS.md`. Read it to see what the files look like mid-project.
