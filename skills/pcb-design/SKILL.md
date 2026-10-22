---
name: pcb-design
description: Design, place, autoroute, audit and order a custom PCB with KiCad and JLCPCB assembly: JLC/LCSC parts, tight placement, multi-core Freerouting, audit loop, fab checks.
---

# PCB design with KiCad + JLCPCB

Use this for any custom board: picking parts, sizing, placement, routing,
3D checks, audits, fab files, ordering, and answering questions about a
board that was built. The lessons come from real boards designed with an AI
assistant, KiCad, Freerouting and JLCPCB assembly. Every "lesson" below is
a mistake that actually happened or a check that actually caught one.

Explain plainly, give sizes in mm and inches for anything physical, and give
one recommendation rather than a survey of options.

## 1. Rules that are never bent

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
   sweeps and renders go there (section 6).

## 2. Requirements before any layout

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
  section 7.
- **Production intent:** what goes on the case label, how units are
  programmed (pogo or Tag-Connect pads instead of a USB connector save
  space), and top-side-only assembly to keep cost down.

## 3. Parts from the JLC / LCSC catalog

**LCSC** is the distributor whose stock JLC assembles from. **EasyEDA**
(same company group) hosts the symbol, footprint and 3D model that JLC
uses to place each LCSC part. Useful sources:

- JLC's parts search (the endpoint behind jlcpcb.com/parts) for live stock,
  price and **library class**. A small script that checks every BOM line
  against stock for N boards plus attrition is worth running on order day.
- EasyEDA's per-part component data (`easyeda.com/api/products/<LCSC#>/components`)
  for the footprint JLC will actually place. Used for the rotation and pin
  checks in section 8.
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

## 4. Schematic as code

Generating the schematic and netlist from a Python table (`gen_sch.py`)
works well with an AI assistant: every part, net and the reason for each
value in a comment, plus a netlist self-check. Keep pad mapping in one
place (`padmaps.py`: footprints, pin-name-to-pad maps, fixed positions,
keep-outs, net classes, silkscreen, locked pre-routes). Diodes and LEDs
carry their direction in the value ("A>K" = pin 1 anode). Never hand-edit
generated KiCad files.

## 5. Sizing and placement: pack it tight

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

## 6. Autorouting on a many-core machine

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

## 7. 3D and mechanical checks

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

## 8. Fab files and self-checks (JLCPCB)

- Negate Y in the CPL (KiCad's Y points down, Gerbers' up), or every part
  lands mirrored.
- JLC places with the EasyEDA footprint, whose zero rotation and origin
  differ per package. Keep a per-LCSC rotation table and **measure it**:
  fetch each part's EasyEDA footprint, match pads by number, find the
  rotation that maps them onto yours, and flag any big origin offset.
  Zero table errors before ordering.
- **Pin-name check:** turn LCSC's footprint by the rotation JLC will use,
  find which of your pads each LCSC pad lands on, and compare LCSC's pin
  name with your schematic's. It catches reversed diodes, swapped FET pins
  and ICs turned 180. Target zero mismatches.
- No solder paste on unfitted pads, and a not-fitted list giving the reason
  for each.
- **Release gate:** the export step runs a fresh DRC on the exact board and
  refuses to write Gerbers unless it is clean.
- Silkscreen: 0.16 mm minimum stroke, every terminal pole numbered from one
  end with its label, model name and revision on the board.
- JLC's free serial QR: draw a solid 5, 8 or 10 mm square on silk and turn
  on the 2D barcode option. It is a counting serial, not a secret, so never
  use it as an ownership or claim code.

## 9. The audit loop (before every order)

**Audit, fix, re-audit, repeat until no BLOCKER or BUG is left.**

1. Write an audit hand-off: what the board is, the exact commit and files,
   what changed since the last audit, a prioritized check list (new
   circuits from first principles, power stages, layout of what moved, fab
   files against the board, silkscreen), a "known and accepted" list so
   auditors don't re-report it, and the report format.
2. Run **several independent auditors** (different AI models or tools, or
   people) on a read-only copy. Give them the files, not your conclusions.
3. Report format: ID, severity (BLOCKER = don't order / BUG = wrong but
   workable / RISK = could bite, with the condition / NOTE), location (file
   and line, or ref and coordinates), evidence in numbers, smallest fix.
   Then what was checked and found correct, and what couldn't be checked.
   Verdict at the top: "would I order these files as they are?"
4. Fix, regenerate, re-run every self-check, then re-audit the changes
   **and** confirm earlier fixes survived. Keep a check table in the fab
   README (DRC, via-in-pad, rotation check, pin check, courtyard overlaps,
   high-voltage clearances, copper-to-edge, diff against the last audited
   files).
5. Turn what's left as RISK into a bring-up test list.
6. Verify the order BOM against the design **part by part** (value, LCSC#,
   package, rating, temperature) before upload.

## 10. Ordering at JLC

- Standard PCBA (modules with pads underneath force it), top side only,
  **Confirm Parts Placement on**, X-ray when modules have hidden pads.
- Order remark: "No substitutions", naming the parts that must not change
  (chargers, regulators, transceivers, an NTC whose B value sets limits).
- In the placement preview check each connector's mouth direction, pin 1
  of every IC, diode and LED cathode marks, and coax connector centring.
- Declare customs honestly with a fitting HS code.
- Cost reality at 5 boards: roughly 45% of the bill was per-order overhead
  (loading fees, setup, stencil, X-ray). Bigger batches and fewer distinct
  parts save the most.
- Quote 2 and 4 layers side by side; at prototype quantities the layer
  count is a small part of the cost.

## 11. Design in compliance (US production)

- Case label area (~40 x 20 mm): product name, model, "Contains FCC ID:"
  for each radio module, country of origin ("Made in China" for a
  China-assembled board), serial or QR.
- Copy the module makers' reference layouts exactly (antenna keep-out,
  50 ohm RF line, recommended bypass caps). Ship one approved antenna at or
  below the module grant's gain on each band.
- Emission-friendly power layout: tight loops, a ground plane, filtering on
  lines that leave the box, and a way to switch converters off. A Part 15B
  test is still needed on the finished product.
- Firmware test mode for the lab; radios off by default where possible.
- Lithium cells: UN38.3 paperwork, a protection IC, and a
  firmware-controlled cut-off.
- Cellular products may also need carrier certification (e.g. PTCRB);
  a certified module shortens it.

## 12. Bring-up lessons for battery + cellular boards

- A modem rail fed from the cell browns out on USB power alone; fit a cell.
- No antenna means no signal; attach it before testing.
- Check the firmware pin map against the order files, not a schematic
  draft.
- Easy to miss on a first battery board: charge status readable by the
  MCU, cell protection, a real power switch, and power for an active GNSS
  antenna.

## 13. Reporting

Lead with the result, sizes in mm and inches, a picture or render where
possible, sources named, and one recommendation. Batch several questions
into one review list rather than asking them one at a time in chat, and
record settled design decisions in the repo (README or AGENTS.md) so the
next session follows them.
