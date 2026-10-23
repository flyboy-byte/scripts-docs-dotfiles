# Sizing, placement, autorouting, 3D checks

Numbers and tool details here are `[reported]` by the skill's author from their own boards, not verified; web endpoints and prices were `[unchecked]` as of 2026-10-22. Check them live before relying on them.

Freerouting is a Java autorouter; if you have no many-core machine, see the fallback in `SKILL.md`.


## Sizing and placement: pack it tight

1. **Fit check first** (no routing): add up each footprint's courtyard area,
   grouped into functional blocks, and shelf-pack them into the outline.
   Draw it to scale over the previous board's outline with a size table
   (mm and inches, area, height with the tallest part and battery).
2. **Pack toward the wire edge, trim from the far edge.** Push every block
   onto the connector row with an even ~0.6 mm routing gap, then shorten
   the board until the empty space is gone. Report the "jammed, unroutable"
   floor and the routable size separately.
3. **Density guide:** about 60% courtyard coverage routes on 2 layers;
   70-77% needs 4 layers (signal / GND plane / signal / signal). About 70%
   fill per block is the practical limit.
4. **Fixed parts first:** mounting holes and keep-outs, connector row flush
   with the edge, module antenna at a board edge with a copper-free strip on
   all layers, RF connectors next to the radio, SIM at an edge with room for
   the ejected card (~4.7 mm for a push-push nano-SIM).
5. **Automatic placement:** simulated annealing on half-perimeter wire
   length. Grow each courtyard by half a gap (0.15 mm worked), refuse moves
   that touch a fixed part, a keep-out or the edge (0.4 mm), and leave GND
   out of the wire length when a plane carries it.
6. **Hand-place and lock the critical loops** before autorouting: buck and
   boost hot loops (switch node on one layer with nothing under it, input
   cap GND right at the IC GND), USB D+/D-, the RF feed with its matching
   parts. Lay them as locked tracks so the router works around them.
7. **Check the back side:** a routing test caught module GND vias sitting
   over a back-side battery tab, which would have shorted the cell.
   Programming-pad holes need a keep-out on the other side too.


## Autorouting on a many-core machine

Pipeline: schematic -> footprints -> board -> locked pre-routes -> Specctra
DSN -> DSN clean-up -> Freerouting -> SES import -> finisher for leftover
airwires -> pours, stitching and island vias -> DRC -> DRC-driven repair
-> DRC -> fab files.

Facts learned the hard way:

- **Freerouting is deterministic** for a given board and cost model. More
  cores on the same layout give the same answer. Variety comes from
  **different placements** (a sweep: N placer seeds, each routed with the
  two best cost models) and different cost models per copy. Via /
  undesired-direction cost pairs that converged: (50, 2.5), (30, 1.8),
  (35, 2.3), (40, 2.0), (65, 3.0), (100, 1.5).
- Run **one Freerouting copy per core**, each with a **private Java temp
  dir** holding its own `freerouting/freerouting.json` (2.0.1 reads its
  settings there and ignores `-mp`). Add a hard wall-clock timeout (some
  cost models loop for 900+ passes) and retry when it writes an empty
  `.ses`.
- **Freerouting 2.5.0** `[reported: wideband carrier, 2026-10-23]`: runs
  headless with `java -Djava.awt.headless=true -jar freerouting-2.5.0.jar
  -de b.dsn -do b.ses -mp 40 --gui.enabled=false`, and honours `-mp`
  (2.0.1 did not). KiCad's Python API exports and imports directly:
  `pcbnew.ExportSpecctraDSN(board, path)` / `pcbnew.ImportSpecctraSES(board, path)`.
  It **necks tracks down** at small pads (0.15-0.19 mm against a 0.2 mm
  rule): widen unlocked tracks below the minimum after import and let DRC
  confirm clearance. It **ignores inner Edge.Cuts** (cutouts) and the
  copper-to-edge rule: add rule areas (no tracks, no vias) around cutouts
  and in a strip inside the edge for routing, then delete them before DRC
  so they don't flag existing copper. Set the default net class width
  before export; that is the width it routes with.
  `--router.automatic_neckdown=false` stops the neck-down, so there's nothing to widen. It **stops by itself** once its
  score stalls for about 10 passes, so `-mp` only caps the count and more passes don't help: vary the placement
  (seeds) instead. Read its per-pass log lines (`N unrouted and M violations`): violations before any routing mean
  the export clearance is stricter than the existing copper, and the router loses room to it.
- **When the router leaves 1-3 connections open** on a dense area (different ones each run), route the leftovers
  with a small grid finisher: A* on a 0.1 mm grid over both layers, obstacles = other nets' pads, tracks and vias
  grown by clearance + half the width (plus 0.05 mm for grid rounding), the edge and cutouts, and rule areas.
  Pairs come from DRC's `unconnected_items`. If it finds no path, the leftovers are walled in: route the critical
  nets first (finisher, locked), then run the router around them. `[reported: wideband carrier, 2026-10-23]`
- **Placement by net length, not nearest spot.** A placer that drops each part at the nearest legal spot to a target
  can move parts 15+ mm away without saying so, and routing then fails for reasons that look like congestion. Print
  each part's distance from its target, or better, anneal over legal spots: cost per net = half-perimeter of its new
  pads + distance to the nearest copper the net already has, GND left to the pour. On a crowded area, 0402 passives
  (where voltage and power allow) free more room than any router setting. `[reported: wideband carrier, 2026-10-23]`
- DSN clean-up: strip pre-filled zones (they wall off whole layers), move
  nets into their class blocks (KiCad can export the classes empty), and
  keep a plane layer out of routing on 4-layer boards.
- **Score each run by DRC count** (open connections + violations after
  finish and repair), not Freerouting's own number. Keep the best and
  tie-break on fewest vias.
- Freerouting ignores via keep-outs. Count vias inside SMD pads (JLC leaves
  vias open, so solder wicks down and starves the joint) and nudge them
  out. Add ~0.6 mm no-via strips inside the board edges.
- 4-layer bugs found: stitching vias landing on inner-layer signals, and a
  fab export that left the inner layers out of the Gerbers. Check both.
- A 12-thread desktop did in ~20 minutes what a 4-core cloud box did in
  2 hours. Watch the machine: one blue-screened (memory error) at 100%
  load with little free RAM. Log temperatures during long sweeps and run
  fewer copies if it recurs.


## 3D and mechanical checks

- Use real maker or EasyEDA STEP models for every user-handled and tall
  part. Stand-ins and missing models hide real problems, and borrowed
  footprints can bring the wrong model (a pin header shown on bare pads).
- For each user-handled part check: wire or card entry direction, overhang
  past the edge, height against the lid, finger and tool access, card eject
  travel, release-button access, nothing blocking it in the enclosure.
- Render on a GPU machine (KiCad's raytracer or Blender) in the fab's real
  mask colour (JLC green is bright) with tin pads: front 3/4, back 3/4, top,
  bottom. Show renders and a placement picture before routing; people spot
  problems in renders that they miss in drawings.
- Export a board STEP and DXF for the enclosure. Quote heights as model
  figures, not measurements.

