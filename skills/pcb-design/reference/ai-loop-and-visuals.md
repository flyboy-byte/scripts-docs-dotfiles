# How the AI drives the board, and how it sees it

The source boards were designed by an AI assistant working through files and command-line tools, with
the owner reviewing pictures. This file is that working method. The rules come from the author's
boards; exact `kicad-cli` subcommands and flags are `[unchecked]` and vary by KiCad version, so run
`kicad-cli <cmd> --help` before relying on one.

## Everything is code or a command, never GUI clicks

| Work | How the AI does it |
| --- | --- |
| Schematic and netlist | Generated from a Python table (`gen_sch.py`); reasons for each value in comments; netlist self-check. See `parts-and-schematic.md` |
| Footprints, fixed positions, keep-outs, net classes | One mapping file (`padmaps.py`) |
| Placement | Script: fit check, then simulated annealing; critical loops locked by hand in code. See `placement-and-routing.md` |
| Routing | Specctra DSN out, Freerouting, SES back in, finisher, pours; best run chosen by DRC count |
| Testing | Scripts, run every time anything changes: ERC, DRC, via-in-pad count, CPL rotation, pin-name, BOM vs stock. See `fab-files-audit-order.md` |
| Fab files | One export script that refuses to run unless the fresh DRC is clean |

Never hand-edit generated KiCad files. Write each check script once in the project's `checks/`,
then just run it and read its short output; never paste a whole `.kicad_pcb` into the chat.

## Seeing the board yourself

You can't judge a layout from numbers alone. After every placement or routing change:

1. Export a picture: schematic and board layers to SVG/PDF, a 3D render to PNG (`kicad-cli sch
   export`, `kicad-cli pcb export`, and `kicad-cli pcb render` on KiCad 9+). Use the fab's real mask
   colour and tin pads for renders.
2. **Open the image and look at it** (read the PNG) before telling the owner anything. Check what the
   numbers can't: a connector mouth facing inward, a part hanging off the edge, a crowded corner,
   silkscreen under a part, a missing 3D model.
3. Keep pictures in `renders/<rev>/<stage>-<what>.png` so earlier ones can be compared.

## Measurements

Every physical number is in mm and inches and names where it came from:
- **measured** from a STEP model or the board file (export the board STEP for the enclosure);
- **datasheet**, with the URL in `parts_research.md`;
- **scaled** off a drawing (say so);
- **inferred** (say so).

**Measure the outline from the ordered Edge_Cuts Gerber, arcs included,** then draw it with the CPL
part positions and look at the picture. In the first test of this skill (2026-10-22, a curved
146 x 158 mm macro-pad board), a regex over the `.kicad_pcb` said 37 x 15 mm and a raw Gerber
coordinate min/max said 231 x 179 mm; only the drawing showed which was right.

**Without KiCad installed** the Gerbers, CPL, BOM and `.kicad_pcb` are all text: parse them in Python
for the outline, positions, rotations and part counts, render the drawing to PNG (`rsvg-convert`), and
say plainly what still needs `kicad-cli` (DRC, ERC, 3D renders, re-plotting Gerbers to diff).

Report at least: board size, area, courtyard coverage % per block, tallest part height, overhang past
each edge, card or plug travel for user-handled parts. Heights from models are model figures, not
measurements of a real board.

## Showing the owner: artifacts

At the two review points (fit check, and renders before ordering) and for every audit report, publish
a page the owner can open on any device, phone included, rather than describing it in chat. Where the
Artifact tool is available, publish one page per review:
- **Fit check:** the to-scale picture over the previous outline, the size table (mm, in, area,
  height), courtyard coverage, and the one recommendation.
- **Renders:** front 3/4, back 3/4, top, bottom, plus a close-up of each user-handled part, with the
  questions to answer listed under them.
- **Audit:** verdict first, findings table, what was checked.

Republish the same page as the design changes so the link stays the same; record the link in
`STATE.md`. Batch questions on the page into one review list. `[judgment]`: the author showed pictures;
the artifact page is how that is done here.
