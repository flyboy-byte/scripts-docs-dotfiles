# STATE — <board name>

Status: <stage> (<YYYY-MM-DD>)
Revision in progress: <letter>   Revision letters used: <A (ordered YYYY-MM-DD), B (never built), ...>

## Stages
Mark a stage done only when its exit condition is true. Strike through, don't delete.

| # | Stage | Exit condition | Done |
| --- | --- | --- | --- |
| 1 | Requirements | `REQUIREMENTS.md` answered by the owner; breakout/perfboard ruled out | |
| 2 | Parts | Every part in `parts_research.md` with pinout, land pattern, temp rating, stock, source URL; real 3D model seen for user-handled and tall parts | |
| 3 | Schematic | Generated from code; netlist self-check passes | |
| 4 | Fit check | Picture to scale with size table (mm + in) approved by the owner | |
| 5 | Placement | Fixed parts and critical loops locked; back side checked | |
| 6 | Routing | Best run chosen by DRC count, not router score; vias out of SMD pads | |
| 7 | 3D and mechanical | Access check done for every user-handled part; renders shown to the owner | |
| 8 | Fab files | Fresh DRC clean; CPL rotation table and pin-name check at zero mismatches | |
| 9 | Audit | `AUDIT.md` round with no open BLOCKER or BUG; earlier fixes re-confirmed | |
| 10 | Order | Files committed to `fab/<rev>/` the same day, with order number | |
| 11 | Bring-up | RISK items from the audit tested on the real board | |

## Decisions already made (do not re-ask)
- <YYYY-MM-DD> <decision> — <why>

## Checks
| Check | Last result | Date | On files |
| --- | --- | --- | --- |
| DRC | | | |
| CPL rotation | | | |
| Pin-name | | | |
| Via-in-pad | | | |
| BOM vs stock | | | |

## Open
- <question or task, with who decides>
