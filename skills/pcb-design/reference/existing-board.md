# Extending an existing board (someone else's KiCad project)

`[reported: wideband carrier, 2026-10-23]` unless tagged otherwise. For when the board already exists (an
open-source project, an older revision) and the job is to add to it, not draw it from scratch.

## Keep the original as the base

- Work on a branch of the upstream repo; `master` stays equal to upstream, so `git diff master` is
  exactly your change. Generate from `git show master:<file>` every time, so a rerun gives the same
  result and upstream updates can be pulled in.
- Upgrade old files first: `kicad-cli sch upgrade` and `kicad-cli pcb upgrade` write the current
  format. Export the netlist before and after and compare (nets as sets of ref/pin) before trusting it.
- Read the mating board's own files. A carrier's silkscreen labelled module pads TX/RX/nRESET while the
  current module's PCB had SEL_1/SEL_2/VBatt_Sense on them: the carrier was drawn for an older module.
  Count and name pins from the mating board's netlist, not from a symbol drawn for the other board.
- Grep the firmware before calling a pin unused, and never conclude "unused" from search output cut
  short by `head` or a limit.

## Schematic: add parts as code

- Embed library symbols from KiCad's installed libraries into the schematic's `lib_symbols`, flattening
  any `extends` (several KiCad symbols, e.g. REF3030 and 1N4148W, extend another).
- A pin's `(at x y)` in a symbol is its connection point. In the sheet, y points down: for an unrotated
  instance at (X, Y) the pin end is (X + x, Y - y); with rotation a (counterclockwise on screen) it is
  (X + x cos a - y sin a, Y - x sin a - y cos a).
- Connect with local labels and power symbols placed exactly on pin ends; no wires needed. Derive UUIDs
  from names (uuid5) so reruns are stable.
- Netlist self-check after every generation: export the netlist and assert every net in the generator's
  table holds exactly its listed pins and no new pin is left floating. It caught two symbols whose pins
  landed on the same point and merged an unused op-amp into a CAN line.
- Add PWR_FLAGs for nets fed through a passive part, and replace dangling labels with no-connect flags,
  so ERC reaches zero and stays a useful gate.
- Use a bigger sheet and a spaced grid for the new block; export a picture and look at it.

## PCB: add footprints, keep the original routing

- Set every pad's net from the schematic's netlist (upstream parts too); that is "update PCB from
  schematic" done in code, and parity is then zero by construction.
- Lock every existing track and via before autorouting so the router only adds. Delete only the upstream
  pieces you mean to reroute, chosen by net and area, and say why (low current, crossing the free area).
- Check each zone's layer set before calling stitching vias useless: a pour can cover both layers while
  its bottom fill was simply never saved. Removing those vias leaves islands.
- Keep new tracks off other nets' pours during routing (a rule area over them). A new top-side track cut
  an input-power pour in two.
- Find the real keep-outs: a stacked module's footprint can carry bottom-side courtyards and an
  Edge.Cuts cutout through the carrier. A small placer (target spot per part, nearest legal position
  checked against courtyards, cutouts, through-hole pads, existing tracks and vias) beats hand
  coordinates when the free area is irregular, but use it only as the start for placement by net length
  (`placement-and-routing.md`): nearest-spot alone moved parts 16 mm without saying so.
- Give each new GND pad its own via to the other layer's pour before routing (locked), and tap a
  power net with a via placed on its existing track next to the new parts, so neither depends on a route
  across a crowded area. Filter footprint pads with `IsOnCopperLayer()` in any clearance check: unnumbered
  paste apertures show up as obstacles otherwise.
- Check the enclosure before growing the board (an STL's horizontal faces give floor and boss heights).
  Bottom-side parts can keep a case fit, at the cost of JLC's second-side assembly.
- Hide the LCSC field on footprints added by script (it is visible by default) and shrink reference text.
- Judge the result against upstream's own DRC baseline, listing only the new violations: make that a
  check script (git-show the original, `kicad-cli pcb upgrade`, DRC both, subtract by type and item
  descriptions), not a procedure in prose.
