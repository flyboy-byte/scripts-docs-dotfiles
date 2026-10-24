# pcb-design

A [Claude Code](https://claude.com/claude-code) skill for designing a custom PCB end to end with an AI assistant:
KiCad for the board, Freerouting for autorouting, JLCPCB / LCSC for parts, fabrication and assembly.

It covers requirements, part choice from the JLC catalog, schematic as code, tight placement, multi-core
autorouting, 3D and mechanical checks, fab files (CPL rotation and pin-name self-checks), an audit loop before every
order, ordering, US compliance notes and bring-up lessons for battery + cellular boards.

Pointed at a folder, it also sets the project up so every later session follows the same procedure: a `STATE.md`
with stages and exit conditions, a requirements interview that picks risk questions from what the board does and
ends with bring-up tests, check scripts, a release gate, a pin map shared with the firmware, an audit pack for a
second model, order and lessons logs, and a review page you can answer from your phone.

It is also a documented workflow: [`WORKFLOW.md`](WORKFLOW.md) describes how an assistant carries a board through
those stages on its own (one change per run, attempt tables, measurement scripts, when to stop and ask, saving the day
at a pause point, cross-model audits). [`flyboy-byte/wideband-work`](https://github.com/flyboy-byte/wideband-work)
is a worked example: a rusEFI wideband controller extended with a 0-5 V output, designed this way.

## Install

```bash
cp -r skills/pcb-design ~/.claude/skills/
```

You also need the tools on the machine where Claude Code runs: [KiCad](https://www.kicad.org) 8 or newer (with its
`kicad-cli`), Java for [Freerouting](https://github.com/freerouting/freerouting) (2.5.0 tested; notes on 2.0.1 too), and Python 3. A
JLCPCB account is only needed when you order. Package names differ per distro, so install them your usual way.
The `kicad-cli` commands in the skill were checked on KiCad 10.0.7.

Optional: copy `owner.example.md` to `~/.config/pcb-design/owner.md` and fill it in (who solders what, your test
gear, how you want to review). The skill reads it and stops asking.

## Scripts (copied into each project's `checks/`; Python 3, standard library unless noted)

| Script | What it does |
| --- | --- |
| `run_all.py` | Runs every check in `checks/checks.json` and writes the results table into `STATE.md` |
| `kicad_check.py` | DRC or ERC through `kicad-cli`, one line with counts by type; report per board in `checks/out/` |
| `cpl_vs_board.py` | Pick-and-place file against the board: positions and rotations |
| `gerber_outline.py` | Board size from the Edge_Cuts Gerber, plus a drawing with part positions |
| `pinmap.py` | `pinmap.csv` to firmware pin headers, and checks they match the board |
| `drift.py` | Lists what someone changed by hand in a generated KiCad file |
| `release.py` | Copies fab files to `fab/<rev>/` only when checks, audit and revision are all clean |
| `audit_pack.py` | Read-only folder and prompt for an independent reviewer |
| `drc_vs_baseline.py` | DRC minus the original board's own errors, for extending an existing board |
| `via_in_pad.py` | Vias in SMD pads, which DRC doesn't flag (needs KiCad's Python module) |
| `finish_routes.py` | For the PCB generator: negotiated routing of a dense net group, and a finisher for what the autorouter leaves (needs KiCad's Python module) |

They run without Claude too: `python3 checks/run_all.py`, `python3 checks/release.py v2 out/*.zip`.

## How to use it without a month of effort

The author's results came from a long, patient loop, not a clever prompt. The skill is the loop written down:

1. Point Claude at the project folder (empty for a new idea, or an existing board project). It copies the
   templates and scripts, sorts ordered files from drafts, and asks the requirement questions the files don't answer,
   one at a time. After that, every session reads `STATE.md` first and works the current stage.
2. Let it pick parts and show you the 3D models before it places anything.
3. Approve a fit-check picture, then let it place and autoroute. Expect many rounds; that is the work.
4. Before ordering, run the audit loop with a second, independent reviewer (another model or a person) on a
   read-only copy. This is the step that catches expensive mistakes.
5. Order a small batch first, and commit the exact uploaded files the same day.

A laptop is fine; routing is just slower (see "no-big-machine fallback" in `SKILL.md`). With few credits, read
`reference/budget-mode.md`: it keeps the checks that matter and drops the sweeps and extra audit rounds.

## Provenance

- Written by sidewinderzz. Content is theirs; on 2026-10-22 it was split into `reference/` files, the description
  was rewritten, evidence tags and a laptop fallback were added, and the project templates in `templates/` were
  written from the author's rules (structure added here, rules theirs). The original copy is in the owner's `parking-lot` repo (received 2026-10-22), unmodified. The author's updated copy
  (received 2026-10-24: zoned placement with a nesting fit check, Freerouting 2.0.1 headless bugs and patching, Java
  memory caps, a correction that 2.0.1 is not repeatable) is kept beside it (`skill-v2/pcb-design/`, unmodified) and merged into
  `reference/zoned-placement.md` and `reference/placement-and-routing.md`.
  MIT licensed; see `LICENSE` in this folder.
- The lessons and numbers in `SKILL.md` (Freerouting cost pairs, cost shares, density guide, run times) are the
  author's own report from real boards. They have not been verified here.
- JLC / LCSC / EasyEDA endpoints, Freerouting 2.0.1 behaviour and JLC pricing were not re-checked as of 2026-10-22
  and change over time.
- Not for one-offs where a breakout board or perfboard does the job, or for designs outside the KiCad + JLCPCB path.
