# pcb-design

A [Claude Code](https://claude.com/claude-code) skill for designing a custom PCB end to end with an AI assistant:
KiCad for the board, Freerouting for autorouting, JLCPCB / LCSC for parts, fabrication and assembly.

It covers requirements, part choice from the JLC catalog, schematic as code, tight placement, multi-core
autorouting, 3D and mechanical checks, fab files (CPL rotation and pin-name self-checks), an audit loop before every
order, ordering, US compliance notes and bring-up lessons for battery + cellular boards.

## Install

```bash
cp -r skills/pcb-design ~/.claude/skills/
```

You also need the tools on the machine where Claude Code runs: [KiCad](https://www.kicad.org) 8 or newer (with its
`kicad-cli`), Java for [Freerouting](https://github.com/freerouting/freerouting) (the 2.0.1 jar), and Python 3. A
JLCPCB account is only needed when you order. Package names differ per distro, so install them your usual way.

## How to use it without a month of effort

The author's results came from a long, patient loop, not a clever prompt. The skill is the loop written down:

1. Start by telling Claude the board's job, size limit, where the wires leave and the temperature range. It writes
   `REQUIREMENTS.md` and asks one question at a time.
2. Let it pick parts and show you the 3D models before it places anything.
3. Approve a fit-check picture, then let it place and autoroute. Expect many rounds; that is the work.
4. Before ordering, run the audit loop with a second, independent reviewer (another model or a person) on a
   read-only copy. This is the step that catches expensive mistakes.
5. Order a small batch first, and commit the exact uploaded files the same day.

A laptop is fine; routing is just slower (see "no-big-machine fallback" in `SKILL.md`). With few credits, read
`reference/budget-mode.md`: it keeps the checks that matter and drops the sweeps and extra audit rounds.

## Provenance

- Written by sidewinderzz. Content is theirs; on 2026-10-22 it was split into `reference/` files, the description
  was rewritten, and evidence tags and a laptop fallback were added. Original copy in the copy in the owner's `parking-lot` repo (received 2026-10-22), unmodified.
  MIT licensed; see `LICENSE` in this folder.
- The lessons and numbers in `SKILL.md` (Freerouting cost pairs, cost shares, density guide, run times) are the
  author's own report from real boards. They have not been verified here.
- JLC / LCSC / EasyEDA endpoints, Freerouting 2.0.1 behaviour and JLC pricing were not re-checked as of 2026-10-22
  and change over time.
- Not for one-offs where a breakout board or perfboard does the job, or for designs outside the KiCad + JLCPCB path.
