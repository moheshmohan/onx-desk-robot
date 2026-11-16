# Notes for AI sessions working in this repository

Read this first. It tells you what the project is, where things are, what is true, and how the owner likes to work. It is written for an assistant that has never seen the project.

## What this is

A set of 3D-printable holders for the Open Nextion ONX2424G013 (a 1.28 inch round ESP32-S3 display with a knob around it), and a demo firmware for it. The holder that was actually built is a small one-piece robot whose head holds the display as its face.

Current goals (November 2026): **an article and a YouTube video** about the project. The source material for both is in `docs/`.

## Where things are

| Path | What it is |
|---|---|
| `docs/ARTICLE.md` | The full write-up: design, print, firmware. Start here for the story |
| `docs/VIDEO_BRIEF.md` | Video planning: angles, beats, quotes, existing footage, shots to film, claims to avoid |
| `docs/PROJECT_LOG.md` | **The fact sheet.** Timeline, every number and how it is known, open questions |
| `docs/HARDWARE.md` | Pins, panel, memory, mechanics, flashing |
| `docs/media/` | Simulator renders of the demo (PNG, GIF) |
| `docs/media/print/` | Real screenshots from the print: slicer, send dialog, 21 camera checks, timelapse |
| `designs/robot-onepiece/` | The robot that was printed. OpenSCAD source, STLs, renders |
| `designs/robot-articulated/` | The earlier posable robot. Never printed |
| `designs/robot-desk-seat/` | Optional base both robots clip onto. Never printed |
| `designs/desk-stand-cc1101/` | Tilted stand with a 433 MHz radio bay. Never printed |
| `designs/panel-puck/` | Flat cup for panel mounting. Never printed |
| `firmware/onx_showcase/` | Demo firmware: `gfx.h` renderer, `scenes.h` scenes, `.ino` device code, `sim/` simulator |
| `firmware/tools/` | Factory firmware backup and restore scripts |

Not in the repository (kept in the owner's local `vendor/` folder, ignored by git): Nextion's dimension drawing, schematic, STEP and DXF files, shop listing images for the CC1101 module, and the 16 MB factory firmware image read from the owner's unit. They belong to other people or are specific to one device. Do not add them.

## Truth rules

1. **`docs/PROJECT_LOG.md` is the source of facts.** Every number there is tagged measured, from the maker, calculated, reported or unknown. Keep those tags when you reuse a number. A calculated print time is not a print time.
2. **Do not invent results, footage or quotes.** The owner's quotes in `docs/VIDEO_BRIEF.md` are verbatim. If you need something that is listed as unknown, ask the owner.
3. **Say what was and was not printed.** Only the one-piece robot was printed, once, on 12 November 2026. The owner reported on 17 November that the plate fits the display and the knob presses fine. The other four designs have never been printed.
4. **Simulator renders are not photos.** `docs/media/scene_*` come from the firmware's drawing code run on a computer. Label them as rendered or simulated.
5. **The owner has detailed video clips of the finished robot with everything working.** They are not in this repository; he will provide them to the session doing the video. Until you have them, the only real images are the printer camera frames and slicer screenshots in `docs/media/print/`. Describe only what you can see in a clip, and add any new fact it shows to `docs/PROJECT_LOG.md`.
6. **When an open question gets answered, write it down:** `docs/PROJECT_LOG.md` first, then the README of the design concerned, then the article.
7. **Privacy.** Never publish the owner's email address, network addresses, printer host name or account names. The app screenshots have the printer's name and address painted over; keep that in any re-crop. Commits use the owner's GitHub no-reply address.

## Design rules (hardware)

- **Only the Ø43.27 fixed base of the display may touch a print.** The Ø48 knob overhangs it and must turn and press freely. Rims stop 1.5 mm (`press_gap`) below the knob.
- **Mirror anything that mates with the back.** Nextion's drawing is a back view. Every STL exported before 11 November 2026 was wrong because of this. In the stand it is `mirror_fix = true`; in the robots it is `pf()`, with `flip_pattern` as a switch.
- **Put unverified dimensions on the smallest part.** In the robots that is the mount plate (`flip_pattern`, `plate_t`).
- **No supports.** The robots allow no overhang beyond 40 degrees.
- **Fewest parts.** The owner dropped a ten-piece posable robot for a one-piece print: "lets ditch the articulation, i want a fast single print". For new designs, default to the fewest parts and no assembly hardware, and state print time and part count up front. Do not add mechanisms unless asked.
- Every design is one parametric OpenSCAD file with a `part` selector. Export commands are at the top of each file and in each README.
- After changing a model, re-export the STLs and re-render the previews so they match.

## Firmware rules

- **Never call `Serial.print` directly.** Use `logf()` in `onx_showcase.ino`. A blocking print froze the device twice. After flashing, confirm the device keeps running with nothing reading its log.
- **You cannot see the screen. Use the simulator.** `gfx.h` and `scenes.h` are portable C++ with no hardware calls, so they compile on a computer. `python3 firmware/onx_showcase/tools/make_media.py <dir>` builds the simulator and writes images you can look at. Check graphics there before flashing. Keep hardware calls out of those two files.
- The simulator shows exactly the pixels the panel receives. It cannot show colour accuracy, brightness or orientation. Ask the owner to look.
- Build and flash: `firmware/onx_showcase/build.sh flash` (arduino-cli, esp32 core 3.3.6, LovyanGFX). Board options are in that script.
- The frame buffer must be allocated in internal RAM before anything else. In PSRAM the demo runs at 18 frames per second.
- The ESP32-S3 has no float square root or divide instruction. Use `fsqrt()` and `frecip()` from `gfx.h` in per-pixel code.
- Knob and button are sampled 1,000 times a second in a task. One click is one quadrature transition on this unit.
- Back up the factory firmware before flashing a unit for the first time (`firmware/tools/backup_factory.sh`).
- Reading the log without resetting the board from Python: open the port with `dsrdtr=True, rtscts=True`.

## The owner's set-up

Useful if you are working on the owner's own computer; ignore otherwise.

- Printer: Creality K1 Max with CFS, 0.4 mm nozzle, 300 x 300 x 300 mm bed. Slicer: Creality Print 7.
- **Do not run Creality Print's command-line slicer.** It crashes on that machine and the owner sees it as the app crashing. Estimate print times from filament volume and say it is an estimate, or drive the open app's window.
- In the app, "Slice plate" and "Send print" can be operated; the final "Start Print" button could not be pressed by the assistant. Prepare everything up to that dialog and ask the owner to press it.
- Say so before launching any of the owner's desktop apps.
- While watching a print: report problems, do not stop or pause it. The owner decides.
- arduino-cli works. PlatformIO is installed but broken. The display appears as a USB modem serial port.
- The USB link dropped during long flash reads. Read or write big images in chunks with retries.

## How the owner likes to work

- Short, direct messages. Lead with the result.
- Say plainly what is unverified, and when you were wrong.
- Do not ask permission for ordinary steps; do ask before anything that touches hardware in a way that cannot be undone, and before pressing buttons that start a print.
- He notices when things crash on his screen. Tell him before you do something he will see.

## Writing for the article and the video

- Audience: makers who 3D print and tinker with ESP32 boards, plus people curious about building with an AI assistant.
- The honest version is the interesting one: the mirror mistake, the crashed slicer, the button the assistant could not press, the wrong diagnosis.
- The assistant never "saw" the robot or the screen, and never printed anything "by itself". See "Claims to avoid" in `docs/VIDEO_BRIEF.md`.
- British spelling is used in the firmware and docs ("colour").

## Open questions

Kept in `docs/PROJECT_LOG.md`. The two that mattered most are answered: the plate fits and the knob presses freely. What remains is detail the owner's clips should show (colours, direction, surface finish).
