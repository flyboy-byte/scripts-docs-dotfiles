# <Board name> — PCB project

This is a custom PCB project set up with the `pcb-design` skill (KiCad, Freerouting, JLCPCB/LCSC).
Load that skill for the procedure; this file only says where the state lives.

## Start every session here
1. Read `STATE.md` (stage, revision, decisions already made, what is open).
2. Work the current stage only. A stage is done when its exit condition in `STATE.md` is met, not
   when more docs exist.
3. End the session by updating `STATE.md`.

## Rules for this project
- Facts about a built board come only from `fab/<rev>/` (the files that were ordered) or the board
  itself. Name the file in every claim. Drafts and `archive/` are never evidence.
- Revision letters are never reused; used letters are listed in `STATE.md`.
- Every number names its source (`parts_research.md`, a datasheet URL, a measured STEP, or
  "scaled" / "inferred").
- Generated KiCad files are never hand-edited; change the generator and regenerate.
- Wiring instructions use the silkscreen terminal numbers and labels, never reference designators.
- Nothing is ordered without a clean audit in `AUDIT.md` (no open BLOCKER or BUG).
- Show the owner a picture at the fit check and renders before ordering.

## Files
| File | Role |
| --- | --- |
| `STATE.md` | Living state: stage, revision, decisions, checks, open items |
| `REQUIREMENTS.md` | The owner's answers; what the board must do and fit |
| `parts_research.md` | Per-part facts with a source URL for every value |
| `AUDIT.md` | Audit hand-off and the findings of each round |
| `fab/<rev>/` | Exactly what was uploaded for each order, committed the day it was ordered |
| `archive/` | Designs that were never built |
