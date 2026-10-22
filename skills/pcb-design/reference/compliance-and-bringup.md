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

