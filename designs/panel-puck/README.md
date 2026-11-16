# Panel puck for the ONX2424G013

**Status: designed and checked in CAD, never printed.**

A flat cup for mounting the display in a panel or on a wall. It was the first thing designed in this project.

- Ø48.27 x 13.4 mm, flush with the knob.
- The display's fixed base sits in the pocket; the knob stays 1.5 mm clear of the rim so it turns and presses freely.
- USB-C leaves through an 8 x 14 mm hole in the floor.
- Two M3 bosses for fixing from behind a panel.
- No room for the CC1101 radio. For that, see the [desk stand](../desk-stand-cc1101/).

| File | What it is |
|---|---|
| `onx2424g013_base_case.stl` | The puck, ready to print |
| `onx2424g013_base_case.scad` | Source. The same file as in `../desk-stand-cc1101/`; it builds the stand, base plate and puck |

Re-export:

    openscad -D 'part="case"' -o onx2424g013_base_case.stl onx2424g013_base_case.scad

The hole pattern comes from Nextion's drawing and is mirrored for a part that mates with the back of the display (`mirror_fix = true`). Check it with `../desk-stand-cc1101/hole_template.pdf` before printing.
