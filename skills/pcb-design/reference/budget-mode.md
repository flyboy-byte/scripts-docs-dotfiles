# Budget mode: getting a good board without burning a month of credits

The skill's source boards (including a working LTE + GPS ESP32 dev board) came from long, heavily funded loops:
many routing sweeps, several independent auditors, repeated renders. That is the ceiling, not the entry price.
Most of the value is in a few cheap checks that run as scripts instead of as conversation. Use this when credits,
time or hardware are limited. Everything below is the skill's own advice trimmed, plus judgment (`[judgment]`);
the savings are not measured.

## Where the credits actually go

Spend goes on the model reading and rewriting big files in a loop (layouts, logs, long chats), on repeated routing
and audit rounds, and on re-deriving context in every new session. Cut those, keep the checks.

## Rules for a small budget

1. **Pick the cheapest board that does the job.** Use pre-certified modules (ESP32, LTE) so you copy the maker's
   reference design instead of inventing circuits. Prefer 2 layers and one size up over a squeezed 4-layer board.
   Fewer, simpler boards beat clever ones. `[judgment]`
2. **Let scripts do the checking, not the model.** `kicad-cli` DRC, the CPL rotation check, the pin-name check, the
   via-in-pad count and the BOM-vs-stock check are deterministic. Have Claude write each script once, then just
   run it and read the short result. Never paste a whole `.kicad_pcb` into the chat.
3. **Keep a state file.** A `STATE.md` with the decisions made, the current revision, what passed and what is open.
   Start each session by reading it, end each by updating it. This stops every session re-deriving the project.
4. **Use the right model for each step.** A cheaper model is fine for mechanical work (generating the netlist table,
   running checks, formatting fab files). Use the strongest model you can for requirements, part choice and the
   final audit, where a mistake costs real money. `[judgment]`
5. **One routing run, not a sweep.** One placement, the best cost pair `(50, 2.5)`, one timeout. Only add seeds if
   the DRC count is still high. Cap total routing attempts up front (say 5).
6. **Skip renders until the end.** Do one placement picture before routing and one set of renders before ordering.
7. **Ask all questions in one batch** (the skill already says this); questions in chat cost a round trip each.

## Audit on a budget

Audit is the step not to skip, but it can be tiered:

1. Free: run every script check. Fix until clean.
2. Cheap: one independent reviewer (a different model, a fresh session, or a friend) on a read-only copy, given the
   files and the hand-off, not your conclusions.
3. Only if the board is expensive, radio-heavy or hard to rework: add a second reviewer.

Then order the smallest batch (5 boards). A cheap respin costs less than extra audit rounds on a board that is
fine, but a board with reversed diodes or a swapped FET costs the whole batch.

## Stop points: where to decide whether to keep spending

- After requirements: is a breakout board or perfboard enough? Stop here if so.
- After the fit check: does it fit at an acceptable size? If not, change the requirements, not the placement.
- After the first route: DRC count near zero? Fix by hand or with the finisher before any more sweeps.
- Before ordering: all checks clean and one audit done. Order; don't polish.
