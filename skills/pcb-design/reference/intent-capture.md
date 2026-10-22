# Capturing intent: one interview for any board

`[judgment]`: written for this skill, built on the author's requirement list in `SKILL.md`. One interview works for
every kind of board. Don't pick a "board type" questionnaire; reason about what the board **does** and ask what
those functions make risky. In chat, ask one question per message, each with a recommended answer and why. On the review page (owner profile
says so), post a stage's questions together; that is the one place they are batched. Write answers into
`REQUIREMENTS.md` as they come. Read `~/.config/pcb-design/owner.md` first if it exists and don't re-ask what it says.

## 1. Core (every board)

1. What job does it do, in one sentence, and who touches it?
2. Where does it live (desk, enclosure, vehicle, outdoors, wall) and what temperature range?
3. What powers it, and what does it connect to (USB, wires to sensors, a vehicle, mains-powered gear, radio)?
4. Size limit, which edge is the hard one, where the wires leave, how it mounts.
5. How many, and who solders what (use the owner profile's assembly split).
6. Is a module, breakout or perfboard enough? If yes, say so and stop.

## 2. Risk probes, chosen by function

As soon as you know what the board is for (often from the first message), write its functions and the probes they
trigger into the "Risk probes asked" section of `REQUIREMENTS.md`, with the answers empty. That list is the interview
plan: the next session continues from it instead of re-deriving it. Ask only the probes the functions trigger; a board
usually triggers several.

| If the board... | Ask about |
| --- | --- |
| runs from a vehicle's 12/24 V | load dump and transients (TVS), reverse polarity, ignition-switched vs constant feed and sleep current, -40..+85 C parts, vibration-proof connectors, CAN/OBD access, fuse |
| has a battery | chemistry and cell count, protection IC, charge source and current, fuel gauge or voltage sense, a real off switch, shipping rules (UN38.3) |
| switches or drives loads (motors, relays, solenoids, LEDs strips) | load current and inrush, flyback/snubber, MOSFET vs relay, thermal (copper area), stall current, separate power and logic grounds |
| converts power (buck/boost/charger) | input range, output currents, efficiency vs heat, hot loop layout, switch off for sleep |
| has a radio (Wi-Fi, BLE, LTE, LoRa, GNSS) | pre-certified module, antenna and keep-out, enclosure material, labelling (`compliance-and-bringup.md`) |
| is a human interface (keys, buttons, encoders, LEDs, HID) | key count and matrix vs I/O expander, debounce, LED drive (sink vs source, current), USB HID vs serial, ESD on touchable parts |
| connects to USB | connector type and strength, ESD, CC resistors for USB-C, power role, enumeration name |
| reads sensors | signal levels (3.3 V vs 5 V), cable length, pull-ups, noise filtering, calibration |
| touches mains | stop: recommend a certified module or relay board, and say why |
| ships to other people | case label, compliance, programming in production |

## 3. What "working" means (decide before any layout)

End the interview by writing numbered **bring-up tests** in `REQUIREMENTS.md`, each one checkable with the owner's
bench (owner profile): what to do, what to measure, the pass value. Examples: "T1: unpowered, resistance 5V to GND
> 1 kOhm"; "T4: press each key, host sees keys F13-F24 in order". The audit and bring-up are judged against these.
Changing a test later needs a dated reason in `STATE.md` (decided in advance so results can't be argued after).
