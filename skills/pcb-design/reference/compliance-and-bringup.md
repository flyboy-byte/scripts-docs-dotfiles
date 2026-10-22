# Bring-up for any board, then US compliance and battery + cellular notes

## First power-up on a small bench `[judgment]`

Every board, before anything else. Written for a multimeter and a soldering iron; a bench supply makes it easier but
isn't needed.

1. **Look first.** Under light and magnification: solder bridges on hand-soldered pins, part orientation (diodes,
   LEDs, ICs, polarised caps) against the order CPL and silkscreen.
2. **Short check, unpowered.** Meter on resistance across every rail to GND. Write the readings in `STATE.md`.
   Near 0 ohm means stop and find the short. A low but rising reading is capacitors charging and is fine.
3. **Current-limited first power.** Without a bench supply: a USB power meter between charger and board (watch the
   current), a polyfuse or a series resistor on a spare cable (e.g. 10 ohm for a board expected to draw < 100 mA:
   the drop shows the current), or a laptop USB port that cuts out on overcurrent. Write the limit you used.
   Unplug at once if current is far above what the board should draw, or anything gets hot (finger test).
4. **Rails.** Measure each rail's voltage against the expected value.
5. **Then the bring-up tests** in `REQUIREMENTS.md`, in order, writing pass/fail and the reading in `STATE.md`.
   A failure is a finding: add it to `LESSONS.md` with what caught it.

Hand-fitted parts follow the owner profile: if the owner has only an iron, choose through-hole, castellated modules
and 0805 or bigger for anything they solder; QFN and fine pitch go to the fab.

# US compliance and bring-up (battery + cellular boards)

Only read this for products that radiate, carry lithium cells or ship in the US. Skip it for a bench or hobby board.


## Design in compliance (US production)

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


## Bring-up lessons for battery + cellular boards

- A modem rail fed from the cell browns out on USB power alone; fit a cell.
- No antenna means no signal; attach it before testing.
- Check the firmware pin map against the order files, not a schematic
  draft.
- Easy to miss on a first battery board: charge status readable by the
  MCU, cell protection, a real power switch, and power for an active GNSS
  antenna.

