# Parts from the JLC / LCSC catalog, and schematic as code

Numbers and tool details here are `[reported]` by the skill's author from their own boards, not verified; web endpoints and prices were `[unchecked]` as of 2026-10-22. Check them live before relying on them.


## Parts from the JLC / LCSC catalog

**LCSC** is the distributor whose stock JLC assembles from. **EasyEDA**
(same company group) hosts the symbol, footprint and 3D model that JLC
uses to place each LCSC part. Useful sources:

- JLC's parts search (the endpoint behind jlcpcb.com/parts) for live stock,
  price and **library class**. A small script that checks every BOM line
  against stock for N boards plus attrition is worth running on order day.
- EasyEDA's per-part component data (`easyeda.com/api/products/<LCSC#>/components`)
  for the footprint JLC will actually place. Used for the rotation and pin
  checks in `fab-files-audit-order.md`.
- LCSC/JLC product pages for datasheets, ratings and the STEP model.
- The community `jlcparts` index for offline parametric search.
- Cloud sandboxes are often blocked from LCSC, JLC PDFs and EasyEDA. Fetch
  from a local machine if so.

Choosing parts:

- **Basic** parts have no loading fee; **Preferred** are Extended parts
  with no fee; **Extended** parts cost a loading fee per distinct part per
  order (about $1.50-3). On a 5-board prototype that fee was ~29% of the
  bill. Prefer Basic, and merge values (one TVS type, one small FET, fewer
  resistor values). 0402 passives are the economical floor; 0201 costs
  more and is hard to rework.
- **The maker's datasheet beats everything.** When the maker drawing and
  the EasyEDA footprint disagree, use the maker drawing and note the
  difference. Record per part: pinout, land pattern, keep-outs (e.g. no
  copper or vias under SIM contacts), body size and height, temperature,
  current, wire range, card or plug travel. Keep it in a
  `parts_research.md` with a URL per value.
- **Get the real 3D model before committing to a connector.** Lessons: a
  push-in terminal block that looked fine on paper turned out 14 mm deep
  and 12.8 mm tall, and hung 4.6 mm off the board edge. A "2.54 mm pitch"
  screw block was 5.56 mm wide per 2-pole block, so eleven didn't fit the
  row; a different maker's block was exactly 5.08. Measure the STEP, don't
  trust the listing.
- Recheck stock on order day. Modems, SIM sockets and supervisors run thin.
- Look for hidden mechanical features: locating pegs on battery holders
  (one common 18650 holder has three, ~3.5 mm long), pegs under modules.
  JLC's standard service doesn't drill partial-depth holes.


## Schematic as code

Generating the schematic and netlist from a Python table (`gen_sch.py`)
works well with an AI assistant: every part, net and the reason for each
value in a comment, plus a netlist self-check. Keep pad mapping in one
place (`padmaps.py`: footprints, pin-name-to-pad maps, fixed positions,
keep-outs, net classes, silkscreen, locked pre-routes). Diodes and LEDs
carry their direction in the value ("A>K" = pin 1 anode). Never hand-edit
generated KiCad files.

