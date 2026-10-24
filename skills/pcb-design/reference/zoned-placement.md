# Zoned placement with a nesting fit check

`[reported]` by the skill's author (sidewinderzz) from a ~200-part board, received 2026-10-24 in their updated skill;
not verified here. Use it on a dense board where blocks compete for space. A small add-on stage on an existing board
(the wideband carrier) placed fine without it.

On its own, an annealer minimising wire length scatters functional blocks all over the board (power parts mixed in
with RF parts). The person knows where each circuit block belongs better than any wire-length number does. Let them
draw it, check that it fits, then let the placer work inside it.

1. **Zones = schematic blocks**, grouped by what the circuit does (power input, charger, switched rails, MCU support,
   radio, terminal protection, each interface). Give each block a letter in the schematic table so every part carries
   its zone.
2. **A zone planner page.** A small web page (an artifact works) showing the real outline to scale with holes,
   keep-outs and fixed parts. The person drags one shape per block. Make shapes polygons, not just boxes: drag corners,
   add and remove corners, a "square up" button that turns slants into steps. A zone can be several shapes and may wrap
   around fixed parts (their area doesn't count as free space). Show fill % per zone and the wire pulls between blocks.
   Worth adding: live packing in the page (bottom-left packing on a fine grid, retrying other corners and part orders)
   so the person sees immediately which parts don't fit, undo, and "split into two zones" with tap-to-assign part chips
   for blocks that need to straddle something. Save the plan to the page's storage so the assistant can read it back,
   and let the assistant write fit and placer results back for the page to show.
3. **zones.json**, the file form: `{"zones": {"A": [shape, ...]}, "fixed": {ref: [x, y, rot]}, "assign": {ref: "A2"}}`
   in mm. A shape is a box `[x0, y0, x1, y1]` or a polygon `[[x, y], ...]`. Say clearly whether `fixed` is the
   footprint origin or its centre (they differ).
4. **Real fit check with a nesting engine.** Use a true 2D polygon nesting library (the same kind of engine that nests
   parts on a CNC plasma or laser sheet) to pack each zone's courtyards at real size, a gap apart, pushed toward the
   wire edge. Use square-cornered spacing that matches the placer's rule (many nesting engines space with round
   corners, which lets parts sit closer than the placer will allow). Pack zones one at a time so packed parts block the
   next zone and overlapping zones share space, re-check the result for overlaps, and print which parts don't fit each
   zone. Run it after every zone change, before any placer run.
5. **Zone-aware placer.** Add a penalty per mm a part sticks out of its zone (~20 per mm against the wire-length cost
   worked) and start every part inside its zone, ideally from the nested packing. A penalty of 0 or no zones file means
   free placement. Report how many parts ended inside their zone.
6. **What it did on a ~200-part board** (90 s anneal, same seed): free placement had the shortest estimated wire
   length; zones from a centre start were ~24% longer with 189/205 parts inside; a nested start was ~30% longer with
   200/205 inside. Packing keeps blocks tightest, but **whether that routes better is decided by a DRC-scored routing
   sweep of zoned vs free placements, not by the estimate.**
7. If there's no KiCad where the placer runs, a tiny regex stand-in for the `pcbnew` module (load board, footprints,
   courtyards, pads) built from the `.kicad_pcb` is enough for quick placer and fit tests. Real sweeps still run with
   KiCad.
8. Existing products: Quilter and DeepPCB do AI placement and routing as paid cloud services (you upload the design).
   As of late 2026 nothing free does general KiCad auto-placement `[reported]`, which is why this kit exists.
