# Fab files, audit loop, ordering at JLC

Numbers and tool details here are `[reported]` by the skill's author from their own boards, not verified; web endpoints and prices were `[unchecked]` as of 2026-10-22. Check them live before relying on them.


## Fab files and self-checks (JLCPCB)

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


## The audit loop (before every order)

**Audit, fix, re-audit, repeat until no BLOCKER or BUG is left.**

1. Write an audit hand-off: what the board is, the exact commit and files,
   what changed since the last audit, a prioritized check list (new
   circuits from first principles, power stages, layout of what moved, fab
   files against the board, silkscreen), a "known and accepted" list so
   auditors don't re-report it, and the report format.
2. Run **several independent auditors** (different AI models or tools, or
   people) on a read-only copy. On a small budget one is enough (see
   `budget-mode.md`). Give them the files, not your conclusions.
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

