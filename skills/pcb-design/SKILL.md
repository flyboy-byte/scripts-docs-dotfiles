---
name: pcb-design
description: Design, lay out, autoroute, audit and order a custom PCB with KiCad, Freerouting and JLCPCB/LCSC assembly. Use when the user says "design a PCB", "make a board", "KiCad layout", "order boards from JLC", "pick LCSC parts", "check my gerbers/BOM/CPL" or asks about a board they already built.
---

# PCB design with KiCad + JLCPCB

Scope: KiCad + JLCPCB assembly. `reference/compliance-and-bringup.md` (US compliance, battery/cellular bring-up) apply only
to radio, lithium or shipped products. For a one-off, a breakout board or perfboard is usually the better answer; say
so before starting a layout.

Evidence: claims here are the author's report from real boards. `[reported]` = their number, unverified; `[unchecked]`
= web endpoint or price not re-checked (dated 2026-10-22). Say so when you quote one, and check live where you can.

Use this for any custom board: picking parts, sizing, placement, routing,
3D checks, audits, fab files, ordering, and answering questions about a
board that was built. The lessons come from real boards designed with an AI
assistant, KiCad, Freerouting and JLCPCB assembly. Every "lesson" below is
a mistake that actually happened or a check that actually caught one.

Explain plainly, give sizes in mm and inches for anything physical, and give
one recommendation rather than a survey of options.

## Rules that are never bent

1. **Facts about a built board come only from the files that were ordered**
   (the Gerbers, BOM and CPL uploaded to the fab) or from the board itself.
   Say which file you checked in every claim ("the order BOM says J8 is
   C18077633"). Never answer from a draft, an archived design, or a repo
   file that was not the order. If the board disagrees with the files, the
   board wins: write down what you found and fix the files.
   *Lesson:* an assistant read a never-built draft and described the wrong
   SIM holder mechanism for the board on the bench.
2. **Commit the exact uploaded files the day you order** (a `fab/` folder:
   Gerber zip, BOM, CPL, not-fitted list, DRC report, README with the order
   number and date). Move unbuilt designs to `archive/` with a README saying
   "never built".
3. **Revision letters are never reused.** Drafts that were never ordered
   still burn their letter, so a letter always means one thing.
4. **Wiring instructions use the terminal numbers printed on the
   silkscreen**, the label beside each, and the sensor's pin name. Never
   reference designators. Check logic levels (3.3 V MCUs are usually not
   5 V tolerant). Wrong wiring can kill a board: get it right the first time.
5. **Every number you quote names its source**, and "not found" is said out
   loud. Mark values measured off a drawing by scaling as **scaled**.
   Separate "measured" from "inferred" in audits.
6. **Heavy compute runs on the most powerful machine available** (many
   cores, a GPU), not a small cloud container. Autorouting, placement
   sweeps and renders go there (see the fallback below).

## Requirements before any layout

Write these down in a `REQUIREMENTS.md` and get the owner's answers (one
question at a time, with a recommended option) before placing anything:

- **Size target** and which edge is the hard limit. Show mm and inches.
- **Wire edge:** every field wire, battery lead and plug leaves ONE edge.
  Antenna connectors and the radio/SIM cluster at one short end.
- **Mounting:** a hole in every corner and rounded corners (JLC cuts them
  at no cost). Use nylon screws near an on-board antenna and keep holes off
  the antenna corner.
- **Temperature:** outdoor gear needs **-40 C** on every part. Many cheap
  parts are -25 C (some nano-SIM sockets are -25 C while a sibling part
  number is -40 C). Check every connector, holder, crystal, LED and IC, and
  flag anything that isn't rated -40 C.
- **User-handled parts** (terminals, SIM, buttons, battery, pigtails,
  programming pads): list them. Each one gets the 3D access check in
  the 3D check in `reference/placement-and-routing.md`.
- **Production intent:** what goes on the case label, how units are
  programmed (pogo or Tag-Connect pads instead of a USB connector save
  space), and top-side-only assembly to keep cost down.

## Workflow and where the detail lives

Work through these in order; read the reference file when you reach the step.

| Step | Read |
| --- | --- |
| Pick parts, check 3D models, schematic as code | `reference/parts-and-schematic.md` |
| Fit check, placement, autoroute, 3D and mechanical checks | `reference/placement-and-routing.md` |
| Fab files, rotation and pin-name checks, audit loop, JLC order | `reference/fab-files-audit-order.md` |
| Radios, lithium cells, US labelling, bring-up | `reference/compliance-and-bringup.md` |

The pipeline there names helper scripts (`gen_sch.py`, `padmaps.py`, DSN clean-up, a finisher). They are **not
shipped** with this skill: write them in the project as you go, and keep the ideas, not the names, if the project
differs.

## Heavy compute, and the no-big-machine fallback

Autorouting sweeps want many cores (the author's 12-thread desktop did in ~20 min what a 4-core box did in 2 h
`[reported]`). With only a laptop: run fewer placement seeds (3-5) with the two best cost models, give each run a
wall-clock timeout, and let it run unattended. The result is the same quality, just slower. Do not skip the DRC
scoring or the audit loop to save time.

## Reporting

Lead with the result, sizes in mm and inches, a picture or render where
possible, sources named, and one recommendation. Batch several questions
into one review list rather than asking them one at a time in chat, and
record settled design decisions in the repo (README or AGENTS.md) so the
next session follows them.
