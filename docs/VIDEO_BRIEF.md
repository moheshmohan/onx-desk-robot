# Video brief: the desk robot with a knob for a face

*Working notes for planning a YouTube video. Written so that another writer, editor or AI session can pick it up cold. Facts are in [PROJECT_LOG.md](PROJECT_LOG.md) and the full story is in [ARTICLE.md](ARTICLE.md); this file is about how to tell it.*

**Rule for anyone using this file:** do not invent footage, quotes, measurements or results. If something is listed under "Not known yet", ask the owner or film it. The owner's quotes below are verbatim from the work sessions, typos included.

## 1. One-line pitch

A bare round knob display becomes a small desk robot: designed in code, printed in 86 minutes while an AI watched the printer, and brought to life with a face that gets dizzy when you spin its head.

## 2. Why someone would watch

- A cute object with a clear before and after.
- An honest look at building hardware with an AI assistant that **cannot see** the parts or the screen, including the two times it was wrong.
- Useful takeaways for makers: designing for no supports, the back-view mirror trap, and a firmware bug that looked like a broken knob.

## 3. Possible angles

Pick one as the spine. The others become segments.

| Angle | Hook | Best for |
|---|---|---|
| **A. "I let an AI babysit my 3D printer"** | The owner walks away; the AI checks the camera every four minutes with orders to report, not to act | Widest audience |
| **B. "This knob has a face now"** | The robot blinking, then getting dizzy | Shorts, maker audience |
| **C. "The bug that looked like a broken knob"** | "It doesn't respond" then "it's stuck now", and the real cause | Embedded developers |
| **D. "We designed four holders and printed the simplest"** | The posable robot nobody printed | Design audience |

Recommendation: A as the spine, B as the cold open, C as the mid-video twist.

## 4. Story beats

1. **Cold open (10 to 15 s).** The robot on a desk. Turn the knob: eyes follow. Spin it: eyes go to spirals. Press: the face wipes to a thermostat. No talking yet.
2. **The problem.** The display as it arrives: a puck with a USB socket and nothing to stand on. Show the knob overhanging the base.
3. **The constraint.** Only the inner base may be touched. The knob turns and presses.
4. **False starts, fast.** Panel puck, tilted stand with a radio inside, then the mirror mistake: every part was a mirror image because the drawing is a back view.
5. **The robot idea.** The display becomes a face. Show the posable version: ten pieces, clicking joints.
6. **The turn.** On screen, the owner's message: *"lets ditch the articulation, i want a fast single print"*. Cut to the one-piece robot.
7. **How it holds the display.** Plate, three screws, lug, gravity. Everything uncertain is on the plate.
8. **The print.** Slicer says 1 h 26 min. The AI gets to the last button and is not allowed to press it. The owner presses Start and leaves.
9. **The watch.** Timelapse of the 21 camera checks with the clock in the corner.
10. **Giving it a face.** Factory firmware asks for Wi-Fi. Back it up, then write a demo from scratch.
11. **Blind graphics.** The AI cannot see the screen, so it builds a simulator and looks at that.
12. **The twist.** *"it doesnt respond to rotations or click of the display"*. The AI blames the knob code and "fixes" it. Then: *"its stuck now"*. The real cause: a debug print waiting for a listener that was only there while the AI was watching.
13. **Payoff.** All six scenes on the real robot. Leave it alone and it plays by itself.
14. **Close.** What is still unverified, what comes next, where the files are.

## 5. Owner's quotes (verbatim)

Use as on-screen text. They are chat messages, lower case and unedited.

- "lets ditch the articulation, i want a fast single print"
- "remove the antenna and make it print even faster, did u open creality print app, i saw it crash"
- "creality print is running, i imported the model, can you check parameters and initiate a print"
- "i clicked start print, its printing now, can you watch it for any issues and if the model is displaced or spagetti forms message me and we can decide to stop the print"
- "the round display is attached on the usb now, it runs some default firmware which asks to connect to ssid, can we flash something that can showcase the device on a video?"
- "it doesnt respond to rotations or click of the display"
- "does the device have an imu to orient display"
- "its stuck now"

## 6. Footage and images that already exist

All paths are relative to the repository root. Everything here is either a CAD render, a simulator render, or a real screenshot from the print session.

### Real screenshots from the print (12 November 2026)

| File | What it shows |
|---|---|
| `docs/media/print/slicer_result.png` | Creality Print after slicing: 1h26m, 44.63 g, line-type table |
| `docs/media/print/send_dialog.png` | "Send to Lan Printer" dialog with the cursor on Start Print. The button the AI could not press |
| `docs/media/print/printing_layer_6.png` | Device tab at 11:04: layer 6 of 385, temperatures, camera |
| `docs/media/print/check_01_1108.jpg` to `check_21_1228.jpg` | The 21 camera views, one every four minutes. File name gives the local time |
| `docs/media/print/timelapse.gif` | The 21 views as an animation with time stamps |
| `docs/media/print/contact_sheet.jpg` | All 21 on one image |
| `docs/media/print/finished_app.png` | The app at 12:28: printer idle, robot complete |

The printer's network name and address are painted over in the app screenshots. Keep it that way in any re-crop.

### Simulator renders of the demo

These are the firmware's own drawing code run on a computer. They are **not** photos of the display. Say "simulated" or "rendered" if used on screen.

| File | What it shows |
|---|---|
| `docs/media/all_scenes.png` | One still of each of the six scenes |
| `docs/media/scene_1_hello.gif` to `scene_6_warp.gif` | Five seconds of each scene |
| `docs/media/scene_*.png` | Eight stills per scene |

More can be made at any length and frame rate: see `firmware/onx_showcase/tools/make_media.py` and `sim/sim.cpp` (`./sim frames <dir> <scene> <seconds> <fps>`).

### CAD renders

| Folder | Renders |
|---|---|
| `designs/robot-onepiece/` | front, back, underside, section, print layout, on seat |
| `designs/robot-articulated/` | exploded, sitting, standing, arms up, section, small parts, test set |
| `designs/desk-stand-cc1101/` | assembly front and rear, cutaways, shell inside, base, wiring diagram |
| `designs/robot-desk-seat/` | seat, section, with robot |

Turntables or exploded animations can be rendered from the `.scad` files with OpenSCAD's command line (`--camera`, `-D`).

## 7. Shots that still need filming

Nothing below exists yet. No photo or video of the real robot or the real screen is in this repository.

- [ ] The display as delivered, in the hand, knob being turned and pressed.
- [ ] Close-up of the knob overhanging the base (the reason for the main design rule).
- [ ] The back of the display: three screw holes, USB-C, headers.
- [ ] The printed robot and plate fresh off the bed.
- [ ] Screwing the plate to the display with the three M1.6 screws.
- [ ] Dropping the display into the head; the lug finding the keyway.
- [ ] Threading the cable up through the body and pressing it into the backpack slot.
- [ ] Each of the six scenes on the real display, with a hand on the knob.
- [ ] The dizzy eyes: spin the knob fast.
- [ ] Holding the knob for one second to rotate the picture.
- [ ] Hands-free: leave it for 15 seconds and film the self-running demo. Good B-roll.
- [ ] Pressing the knob without rubber feet (it slides) and with them.
- [ ] Optional: the K1 Max printing, if a reprint happens.

Filming notes:
- The backlight runs at 100 %, with no dimming, so it should not flicker or band on camera.
- The screen refreshes at 86 Hz and the demo runs at 40 to 55 frames per second.
- Black backgrounds hide the display's edge; expose for the bright colours.
- The Colour scene and the Climate arc are the best tests of whether the camera is handling colour well.

## 8. Facts for captions and lower thirds

All checked against [PROJECT_LOG.md](PROJECT_LOG.md).

- Display: Open Nextion ONX2424G013, 1.28 inch round, 240 x 240, ESP32-S3.
- Robot: 60 x 79 mm footprint, 77 mm tall, 60 mm head.
- Print: 1 h 26 min, 44.63 g, 385 layers, no supports, stock 0.2 mm profile.
- Printer: Creality K1 Max. Filament: red Hyper PLA.
- Parts: 1 robot + 1 plate, 3 screws.
- Print watch: 21 checks, 11:08 to 12:28, one every 4 minutes.
- Demo: six scenes, about 1,250 lines of C++, 40 to 55 frames per second.
- First build: 18 frames per second.
- SPI link tested at 80 MHz: 0 errors in 256 register writes.
- The freeze: about 45 seconds after nothing was reading the log.
- Posable version: 10 pieces, 4 screws, about 81 g, never printed.

## 9. Claims to avoid

- Do not say the AI "printed it by itself". The owner pressed Start Print, and the AI was told not to stop or pause.
- Do not say the AI "saw" the robot or the screen. It saw a low-resolution printer camera and its own simulator.
- Do not call simulator renders photos or screen captures of the device.
- Do not say the fit is confirmed. See "Not known yet".
- Do not say the stand, puck, posable robot or seat were printed. They were not.
- Do not say the radio works. It was never wired.
- Do not quote the faster print time (about an hour, 39 g) as a result. It is a calculation.
- Do not show the printer's network address or any account names.

## 10. Not known yet (ask the owner)

- Did the plate's holes line up with the display, or was `flip_pattern` needed?
- Does the knob press freely in the head, or did it bottom out on the rim?
- Is the picture upright, or how many quarter turns did it take?
- Are the colours right on the real screen? Does clockwise count up?
- Any visible tearing in fast motion?
- How does the surface look, especially under the head?
- Were magnets and rubber feet fitted?
- Does it slide when pressed?

## 11. Title and thumbnail ideas

Titles:
- I Let an AI Watch My 3D Printer While I Was Away
- This Knob Has a Face Now
- An AI Designed This Robot Without Ever Seeing It
- The Bug That Looked Like a Broken Knob
- From Bare Display to Desk Robot in an 86 Minute Print

Thumbnail ideas:
- The red robot with cyan eyes, close, on a dark desk. Two or three words at most.
- Split: printer camera frame on the left, finished robot on the right.
- The dizzy spiral eyes, large.

## 12. Rough chapter list

| Time | Chapter |
|---|---|
| 0:00 | It has a face |
| 0:20 | The display nobody gave a stand |
| 1:00 | One rule: do not touch the knob |
| 1:40 | Three designs and a mirror mistake |
| 3:00 | The robot, and why we threw the joints away |
| 4:30 | An 86 minute print, watched by an AI |
| 6:00 | Writing a face for a screen it cannot see |
| 7:30 | "It's stuck now" |
| 9:00 | All six scenes |
| 10:00 | What we still have not checked |

Timings are placeholders for a ten to eleven minute cut.

## 13. Short explanations for the script

Plain-language versions of the technical points, each safe to read out.

- **Why a plate?** The display has nothing to hold except three tiny screw holes. The plate turns those into something that drops in and lifts out by hand.
- **Why mirrored?** The maker's drawing shows the back of the display. A part that sits against the back sees everything flipped, like a rubber stamp.
- **Why no supports?** Every surface leans no more than 40 degrees from vertical, so each layer always has enough of the one below to sit on. The face is tilted to 50 degrees because that is the angle where the pocket's roof just meets the limit.
- **Why does the AI need a simulator?** It writes drawing code but cannot look at the screen. The simulator runs the same code on a computer and saves pictures it can inspect.
- **What was the freeze?** The robot kept a diary over USB. When nobody was reading it, the diary filled up and the robot stood still waiting for a reader. Now it just skips the entry.
- **Why did the first fix seem to work?** Because while the AI was checking its fix, it was reading the diary.
- **What is dithering?** The screen can show fewer shades than the picture uses. Mixing neighbouring pixels in a fine pattern fakes the missing shades, so glows look smooth.

## 14. Calls to action

- Files: this repository. STLs and OpenSCAD sources are in `designs/`, firmware in `firmware/`.
- Print it: `designs/robot-onepiece/robot_onepiece_print.stl`, stock 0.2 mm profile, supports off.
- Ask viewers: which scene should the robot get next?
