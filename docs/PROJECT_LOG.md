# Project log and fact sheet

The reference for facts. If the article, the video brief or a README disagrees with this file, this file is the one to check and correct first.

Each fact is tagged with how it is known:

- **measured**: read from the device, the slicer or the printer.
- **from the maker**: Nextion's drawing, schematic or published configuration.
- **calculated**: worked out in CAD or by arithmetic. Not tested.
- **reported**: said by the owner.
- **unknown**: nobody has checked.

## Timeline

Dates before November come from file dates, so treat them as approximate.

| Date (2026) | What happened |
|---|---|
| about 21 Sep | Nextion's drawing, schematic and 3D file collected. Panel puck designed. Paper hole template made for checking the drawing against the part |
| about 28 Sep | Tilted desk stand designed. CC1101 433 MHz radio added to it: wiring worked out, radio bay and antenna-jack clamp designed |
| 11 Nov | Mirror error found: all exported parts were mirror images. Fixed in the model, all STLs re-exported |
| 11 to 12 Nov | Robot figurine, then the posable robot: joints, printability review, desk seat, rounded body, overhead arms |
| 12 Nov | Owner asks for one fast print. One-piece robot designed. Antenna removed, head and torso reduced |
| 12 Nov, about 10:10 | Sliced in Creality Print: 1 h 26 min, 44.63 g |
| 12 Nov, about 10:55 | Owner presses Start Print |
| 12 Nov, 11:04 | First look: layer 6 of 385 |
| 12 Nov, 11:08 to 12:28 | 21 camera checks, four minutes apart. No faults seen. Print complete at the last check |
| 15 Nov | Factory firmware backed up. Showcase firmware written, flashed and optimised. Two freezes reported and traced to one bug |
| 16 Nov | Repository organised and published |

Times on 12 November are local (UTC+4).

## The display module

| Fact | Value | Source |
|---|---|---|
| Model | Open Nextion ONX2424G013 | from the maker |
| Panel | 1.28 inch round, 240 x 240, GC9A01A, SPI | from the maker; ID `00 9A 01` measured |
| Processor | ESP32-S3, revision 0.2, dual core, 240 MHz | measured |
| Flash | 16 MB, quad SPI | measured |
| PSRAM | 8 MB, octal | measured |
| USB | Native USB serial and JTAG on the USB-C socket | measured |
| Touch | None | from the maker (schematic) |
| Motion sensor | None | from the maker (schematic) |
| Fixed base | Ø43.27 x 8.4 mm | from the maker |
| Knob | Ø48 x 17 mm, overhangs the base by 2.37 mm per side | from the maker |
| Fixing | 3 x M1.6 threaded holes in the back | from the maker |
| Knob push travel | not published | unknown |
| Weight | not published | unknown |
| Encoder steps per click | 1 quadrature transition | measured (learned by the firmware) |
| Panel refresh | 86 Hz; vertical blank 0.73 ms of an 11.7 ms period | measured |
| Factory firmware | Nextion's ESPHome build, version 1.0.0, ESPHome 2026.3.1 | measured (strings in the backup) |

Pins are in [HARDWARE.md](HARDWARE.md).

## The designs

| Design | Folder | Printed? | Key numbers |
|---|---|---|---|
| Panel puck | `designs/panel-puck/` | no | Ø48.27 x 13.4 mm |
| Desk stand with CC1101 | `designs/desk-stand-cc1101/` | no | 30° tilt, 56 x 51 mm, 23 to 53 mm high, two printed parts |
| Posable robot | `designs/robot-articulated/` | no | 10 printed pieces, 4 x M3 screws, about 81 g, 105 mm tall sitting, body about 6 h (calculated) |
| One-piece robot | `designs/robot-onepiece/` | **yes, once** | 60 x 79 mm footprint, 77 mm tall, 60 mm head |
| Desk seat | `designs/robot-desk-seat/` | no | 68 x 82 x 6.5 mm, fits both robots |

Rules every design follows:

- Only the Ø43.27 fixed base touches the print. The knob stays free.
- The rim stops 1.5 mm below the knob (`press_gap`).
- Positions taken from Nextion's back-view drawing are mirrored for any part that mates with the back.
- No supports. The robots allow no overhang beyond 40 degrees except chamfers and a few square millimetres of detail.

One-piece robot, calculated and not tested:

- A knob press is aimed at a point 41 mm behind the body's centre; the backpack reaches 40 mm. It would have to weigh under about 10 g to tip.
- About two thirds of a press pushes it backward. It needs rubber feet or the seat.

## The print

| Fact | Value | Source |
|---|---|---|
| Printer | Creality K1 Max with CFS, 0.4 mm nozzle, smooth PEI plate | measured (slicer) |
| Filament | Red Creality Hyper PLA | measured (slicer) |
| Slicer | Creality Print 7.3 | measured |
| Profile | Stock "0.20mm Standard": 0.2 mm layers, 2 walls, 15 % grid infill, 5 top and 3 bottom layers, supports off | measured |
| Temperatures | Nozzle 220 °C, bed 50 °C | measured (screenshot) |
| File | `robot_onepiece_print.stl` (robot and plate together) | |
| Time | 1 h 26 min | measured (sliced) |
| Filament | 44.63 g, 14.96 m | measured (sliced) |
| Layers | 385, to 77.0 mm | measured (sliced) |
| Sparse infill share | 13.77 g | measured (sliced) |
| Estimate before slicing | 46 g, 1.25 to 1.75 h | calculated |
| Faster variant | about 39 g, a little over an hour, with lightning infill and 0.24 mm layers | calculated, never sliced |
| Watch | 21 camera checks, 11:08 to 12:28, every 4 minutes | measured |
| Outcome | Complete. No shifting or stringing seen on camera | measured, at camera quality |
| Surface quality | | unknown |
| Fit of plate and display | | unknown |

Things that went wrong around the print:

- Creality Print's command-line slicer crashed twice. The owner saw it. It was not used again.
- The assistant could not press the final Start Print button and did not work around it. The owner pressed it.

## The firmware

| Fact | Value | Source |
|---|---|---|
| Tooling | arduino-cli, esp32 core 3.3.6, LovyanGFX 1.2.21 | |
| Size | 499 KB of a 3 MB app partition | measured |
| Source | `gfx.h` 420 lines, `scenes.h` 511, `onx_showcase.ino` 325, plus generated `fonts.h` | |
| SPI clock | 80 MHz. 256 register writes read back, 0 errors. Factory uses 40 MHz | measured |
| Frame send | 11.3 ms | measured |
| Frame rate | First build 18 fps. After moving the frame buffer to internal RAM, 43. Final: Hello 49 to 56, Climate 48, Sound 45, Time 43 to 51, Colour 43 to 49, Warp 42 to 46. About 40 during a wipe | measured |
| Knob and button | Sampled 1,000 times a second | |
| Input works | Turns and presses seen in the log moving through all six scenes | measured |
| Colours, orientation, direction | | unknown |
| Tearing | | unknown |

The freeze, for the record:

1. First build flashed. Owner: "it doesnt respond to rotations or click of the display".
2. Assistant blames the encoder interrupts and switches to sampling. It appears to work.
3. Owner: "its stuck now".
4. The log shows a 77 second gap that ended the moment a reader attached. Cause: `Serial.printf` on the ESP32-S3's USB serial waits for the host once its buffer is full. With `setTxTimeoutMs(0)` on core 3.3.6, a retry counter starts at 0, is decremented and wraps, so the wait is effectively endless.
5. Fix: write a log line only if `Serial.availableForWrite()` has room for all of it.
6. Test: 100 seconds with no reader, then check. It had kept running.

The interrupt-based input was probably fine. It was never retested.

## Open questions

1. Does the plate's hole pattern match the display, or is `flip_pattern = true` needed?
2. Does the knob press freely in the pocket, or should `plate_t` go up?
3. Colours, upright orientation and clockwise direction on the real screen.
4. Visible tearing?
5. Does the desk seat clip as designed?
6. Does restoring the factory firmware work?
7. Does the CC1101 wiring work?

When one of these is answered, update this file, then the README of the design concerned.
