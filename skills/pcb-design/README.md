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

## Provenance

- Written by sidewinderzz and kept unmodified from the copy in the owner's `parking-lot` repo (received 2026-10-22).
  MIT licensed; see `LICENSE` in this folder.
- The lessons and numbers in `SKILL.md` (Freerouting cost pairs, cost shares, density guide, run times) are the
  author's own report from real boards. They have not been verified here.
- JLC / LCSC / EasyEDA endpoints, Freerouting 2.0.1 behaviour and JLC pricing were not re-checked as of 2026-10-22
  and change over time.
- Not for one-offs where a breakout board or perfboard does the job, or for designs outside the KiCad + JLCPCB path.
