# Fab files, audit loop, ordering at JLC

Numbers and tool details here are `[reported]` by the skill's author from their own boards, not verified; web endpoints and prices were `[unchecked]` as of 2026-10-22. Check them live before relying on them.


## Fab files and self-checks (JLCPCB)

- Negate Y in the CPL (KiCad's Y points down, Gerbers' up), or every part
  lands mirrored.
- JLC places with the EasyEDA footprint, whose zero rotation and origin
  differ per package. Keep a per-LCSC rotation table and **measure it**:
  fetch each part's EasyEDA footprint, match pads **by pin function** (pin
  names, else the cathode band on the silk), find the rotation that maps
  them onto yours, and flag any big origin offset. Pad *numbers* are not
  safe: on one board EasyEDA numbered an SS54's anode 1 where KiCad
  numbered the cathode 1, so pairing by number would have placed it
  reversed. Measure the origin offset on the leads only, not a big
  tab (a TO-252 tab skewed it), and write it as a CPL position shift.
  Zero table errors before ordering. The EasyEDA component JSON
  (`easyeda.com/api/products/<LCSC>/components`) answered a plain
  request and refused a browser user agent `[reported, 2026-10-24]`;
  cache the answers in the repo so the check runs offline.
- **Pin-name check:** turn LCSC's footprint by the rotation JLC will use,
  find which of your pads each LCSC pad lands on, and compare LCSC's pin
  name with your schematic's. It catches reversed diodes, swapped FET pins
  and ICs turned 180. Target zero mismatches.
- No solder paste on unfitted pads, and a not-fitted list giving the reason
  for each.
- **Release gate:** the export step runs a fresh DRC on the exact board and
  refuses to write Gerbers unless it is clean. Count the fab-relevant
  *warnings* too (`hole_to_hole`, `silk_over_copper`, edge clearance):
  KiCad files some of them as warnings, and an errors-only gate hid two
  overlapping vias on one board for about fifteen revisions.
- **Take the BOM from the board, not an old export.** A forked project's
  checked-in BOM/CPL can lag its own board (one upstream export named a
  TVS and a Schottky the board had since replaced). Regenerate from the
  footprints' LCSC fields and compare.
- Check the exported files against the board independently of the
  exporter: regenerate one copper Gerber and compare it (ignoring the date
  line), measure the outline from the Edge_Cuts Gerber, and check every
  CPL row against its footprint plus the rotation table.
- Silkscreen: 0.16 mm minimum stroke, every terminal pole numbered from one
  end with its label, model name and revision on the board.
- JLC's free serial QR: draw a solid 5, 8 or 10 mm square on silk and turn
  on the 2D barcode option. It is a counting serial, not a secret, so never
  use it as an ownership or claim code.


## The audit loop (before every order)

**Audit, fix, re-audit, repeat until no BLOCKER or BUG is left.**

1. Write an audit hand-off: what the board is, the exact commit and files,
   what changed since the last audit, a prioritized check list (new
   circuits from first principles, power stages, layout of what moved, fab
   files against the board, silkscreen), a "known and accepted" list so
   auditors don't re-report it, and the report format.
2. Run **several independent auditors** (different AI models or tools, or
   people) on a read-only copy. On a small budget one is enough (see
   `budget-mode.md`). Give them the files, not your conclusions. An outside
   reviewer with their own AI (a friend's account, another vendor's model)
   counts as more independent than a second model on your own machine:
   give them a one-page brief in the repo (what to read, how to run the
   checks from a fresh clone, what not to change, where the raw report
   goes) and this skill's public link, and keep their raw output as its own
   file.
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


## Ordering at JLC

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

