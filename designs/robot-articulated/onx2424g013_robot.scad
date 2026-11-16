// ---------------------------------------------------------------
// Posable desk robot for the ONX2424G013 (Open Nextion 1.28" round knob display)
// The display is the robot's face. Legs and arms click through 45 degree steps,
// so the robot can stand or sit. Units: mm. Front of the robot = -Y.
//
//   part = "body"     : ball head on a rounded-box torso with a small backpack, one piece
//                       (print standing, no supports)
//   part = "leg"      : print 2, flat. Left and right are the same part flipped over
//   part = "arm"      : print 2, flat
//   part = "hub"      : print 4, cap down. Joint pins, one per limb
//   part = "plate"    : print 1. Mount plate screwed to the back of the display
//   part = "seat"     : optional. Desk seat the sitting robot slides onto and locks
//   part = "test"     : print first. One hub, the mount plate and a joint test piece
//   part = "assembly" : preview; set pose to "sit" or "stand"
//
// Export:  openscad -D 'part="body"' -o robot_body.stl onx2424g013_robot.scad
//
// Display mount
//   The plate is screwed to the display once (3x M1.6). Display + plate drop into
//   the pocket in the head: a lug keys the rotation, gravity (face tilted up) and
//   two optional magnet pairs hold it. Finger slots left and right let you pull
//   it out. Only the D43.27 fixed base touches the print; the D48 knob stays
//   1.5 mm clear so it can rotate and press.
// Cable
//   USB-C runs from the slot at the bottom of the backpack, through the hollow
//   body and a straight channel in the head, to the plug in the pocket.
// Joints
//   A hub pin is keyed into a diamond recess in the body and held by one M3 screw.
//   The limb turns on the pin and never touches the screw, so posing cannot
//   loosen it. The limb's hub is a split ring with two teeth that click into
//   8 notches on the pin.
// ---------------------------------------------------------------

part = "assembly";   // [body, leg, arm, hub, plate, seat, test, assembly]
pose = "sit";        // [sit, stand]
arm_pose = 45;       // arm angle in the preview: 0 down, 90 forward, -90 back
on_seat  = false;    // show the seat under the sitting robot in the preview

/* [Display module, from Nextion's BACK VIEW drawing] */
base_d        = 43.27;
base_h        = 8.4;
cover_d       = 48.0;    // knob
cover_h       = 17.0;
conn_protrude = 2.6;     // connectors stick out this far behind the back plane
holes_bv  = [[-16.90, 0], [8.60, 14.72], [9.11, -14.42]];   // 3x M1.6 nuts
usb_bv    = [-11.0, 0];                                     // USB-C centre
header_bv = [[-5.5, -18.5], [6.5, -7.5]];                   // 2x4 header
uart_bv   = [[13.5, -10.0], [19.6, 1.5]];                   // 4-pin 1.25 connector
// A part that mates with the back sees the MIRROR IMAGE of the back view.
// pf() does that mirror and then turns the module so its USB-C is at the chin,
// on the robot's centre line. If the printed plate's holes turn out mirrored
// against your module, set flip_pattern = true and reprint only the plate.
flip_pattern = false;
function pf(p) = [ (flip_pattern ? -1 : 1) * p[1], p[0] ];
function pfbox(b) = let(a = pf(b[0]), c = pf(b[1]))
    [[min(a[0], c[0]), min(a[1], c[1])], [max(a[0], c[0]), max(a[1], c[1])]];

/* [Display fit] */
radial_clear = 0.6;   // pocket radius minus display base radius
press_gap    = 1.5;   // pocket rim to knob underside (must exceed the push travel)
hole_d       = 2.1;   // M1.6 clearance

/* [Mount plate] */
plate_t      = 3.2;
plate_relief = 1.2;   // recess under the PCB area: only the rim and screw pads touch
plate_under  = 0.15;  // plate radius is this much smaller than the display base
pad_d        = 6.4;
cb_d         = 3.8;   // counterbore for the M1.6 heads (2.0 mm of plastic under the head)
cb_h         = 1.2;
open_r       = 20.4;  // connector openings are clipped to this radius
usb_open     = [15, 8.0];
lug_w        = 6.0;   // anti-rotation lug at the bottom of the plate, below the USB-C
lug_out      = 1.7;
magnets      = true;  // 2 pairs of 6 x 2 mm disc magnets (optional: leave the pockets empty)
mag_hole_d   = 6.15;
mag_t        = 2.0;
mag_recess   = 0.3;
mag_pos      = [[12.5, -11.5], [-12.5, -11.5]];

/* [Head] */
head_r     = 32;
face_r     = 26;      // flat face ring around the knob
face_elev  = 50;      // degrees the face looks up from horizontal. 50 keeps the pocket roof at a 40 degree overhang
neck_polar = 50;      // the ball is buried in the collar up to this angle from its bottom (40 degree overhang above it)
roof_ang   = 50;      // slope of the collar, the body's inner ceiling and the backpack roof, from horizontal
chan       = [16, 9.5];   // plug channel. Rugged plugs reach 13.5 x 7.5
chan_len   = 24;
plug_len   = 25;      // USB-C plug length from the display's back plane to the end of the overmold
scallop_w  = 18;      // finger slots left and right of the pocket
scallop_w0 = 1.0;
antenna    = true;
ant_polar  = 36;
ant_h      = 13;

/* [Body] */
torso_h  = 36;
box_y    = [-21, 30];  // torso: a rounded box. Front and rear face; its flat sides are at +-x_face
box_r    = 10;         // corner radius, seen from above
roof_drop = 8;         // the inner ceiling starts this far below the top of the torso
wall     = 2.4;
floor_t  = 2.0;
bp_w     = 26;        // backpack: cable exit and rear support when sitting
bp_y0    = 20;
bp_rear  = 40;
bp_h     = 8;
slot_w   = 7;         // cable slot in the backpack's rear wall, open at the bottom
slot_h   = 2.5;       // straight part; above it the slot tapers so the cable can be pressed up and gripped
grip_top = 2.2;       // width at the top of the taper
grip_h   = 10;
bottom_open = [18, 28];   // opening in the floor for threading the plug
bottom_open_y = 6;

/* [Joints] */
x_in     = 14.5;      // solid blocks inside the torso carry the joint screws, from here ...
x_face   = 24.6;      // ... to the torso's flat sides, which the limbs sit against. Just over
                      // head_r*sin(neck_polar), so the torso itself supports the head at the sides
hip      = [-2, 10];      // hip axis: y, z
shoulder = [12, 27];      // shoulder axis: y, z. Far enough from the hip and the head that the arm swings full circle
hip_r    = 7.5;
sh_r     = 7.0;
limb_t   = 8.0;
limb_gap = 0.2;       // limb to body
stem_r   = 5.0;
stem_len = 8.5;       // limb_t plus axial play
bore_r   = 5.2;
cap_r    = 7.0;
cap_t    = 2.2;
key_w    = 6.0;       // square key on the hub, diamond recess in the body
key_h    = 2.5;
key_clear = 0.3;
hub_cb   = 6.0;       // screw recess depth, ending in a 45 degree cone (prints cleanly, suits countersunk heads)
edge_ch  = 0.4;       // chamfer on bed-side edges, against first-layer squish
notch_r  = 1.1;       // 8 detent notches on the stem
notch_off = 0.3;
tooth_r  = 1.3;       // 2 teeth on each limb's split ring. Larger radius than the notch, so each
tooth_off = 0.45;      // tooth wedges on the notch's two edges: no play when seated, 0.1 mm preload
tooth_ang = 22.5;
split_w  = 1.4;
root_b   = 4.5;       // the ring is free above this distance below the axis
leg_ring_t = 1.6;     // thicker = stiffer click. Stiffness goes with the cube of this: pick with the test piece
arm_ring_t = 1.2;
test_rings = [1.2, 1.6, 2.0];   // the three eyes on the test piece
pilot_d  = 2.6;       // M3 into plastic
pilot_len = 7.5;

/* [Limbs] */
leg_len  = 24;        // hip axis to sole
foot_len = 16;
foot_h   = 9;
heel     = 2;
arm_len  = 9.5;       // shoulder axis to centre of the hand
arm_w    = 10;
hand_r   = 5.0;

/* [Seat] */
// Fixed to the desk with tape, rubber feet or keyhole screws. The robot's underside
// opening drops over the island, the robot slides back until it stops, and two
// pins click into the opening's rear corners. To release: lift the backpack
// a little and slide the robot forward.
seat_t    = 6.5;
seat_w    = 68;
seat_y    = [-32, 50];   // front and rear edge
seat_r    = 12;
seat_ch   = 1.5;
slide     = 5.5;         // how far the robot slides back to lock
isl_clear = 0.35;        // island to opening, per side
isl_len   = 12;
isl_h     = 6.5;         // island height above the seat top (inside the body)
lip       = 3.0;         // the hook reaches this far over the body's floor
lip_gap   = 0.3;
pin_d     = 3.4;         // locking pins
pin_h     = 1.2;
pin_clear = 0.2;
seat_keyholes = [[20, 38], [-20, 38], [0, -18]];   // entry holes; slots run toward the front
skey_len  = 9;
skey_head = 8.0;         // for #6 / M3.5 pan-head screws
skey_slot = 4.4;
skey_skin = 2.0;
skey_depth = 3.0;
seat_groove = [7, 2.5, 26];   // cable groove: width, depth, start y

/* [Preview] */
show_ghosts = true;
$fn = 96;

// ---------------- derived ----------------
holes   = [for (p = holes_bv) pf(p)];
usb     = pf(usb_bv);
hdr     = pfbox(header_bv);
urt     = pfbox(uart_bv);
plate_r = base_d/2 - plate_under;
pocket_d     = base_d + 2*radial_clear;
pocket_depth = plate_t + base_h - press_gap;
d_face  = sqrt(head_r*head_r - face_r*face_r);
s_floor = d_face - pocket_depth;
collar_r = head_r*sin(neck_polar);
z_n   = torso_h;
roof_t = tan(roof_ang);
z_tt  = z_n + max(0.5, collar_r + box_y[0])*roof_t;   // the collar only flares at the front
zcs   = z_tt + head_r*cos(neck_polar);
Cs    = [0, 0, zcs];
nv    = [0, -cos(face_elev), sin(face_elev)];
knob_c = Cs + (d_face + press_gap + cover_h)*nv;
press_hit_y = knob_c[1] + knob_c[2]*cos(face_elev)/sin(face_elev);
leg_ro = bore_r + leg_ring_t;
arm_ro = bore_r + arm_ring_t;
stand_lift = leg_len - hip[1];

echo(str("ROBOT: ball centre z ", zcs, "  knob centre ", knob_c, "  top of knob z ", knob_c[2] + cover_d/2*cos(face_elev)));
echo(str("ROBOT sitting: knob press line meets the desk at y = ", press_hit_y, "  backpack rear edge y = ", bp_rear));
echo(str("ROBOT: sitting leg clears the desk by ", hip[1] - leg_ro - heel, "  standing lifts the body by ", stand_lift));
assert(face_elev >= 45 && roof_ang >= 45, "below 45 degrees needs supports");
assert(plate_r + lug_out + 0.45 < cover_d/2, "keyway would show past the knob");
assert(hip[1] - leg_ro - heel > 0.3, "sitting leg would touch the desk: raise the hip or shorten the heel");
assert(shoulder[1] - arm_len - hand_r > 0.5, "arm would touch the desk when sitting");
assert(norm(shoulder - hip) > arm_len + hand_r + max(leg_ro, cap_r) + 0.4, "arm sweep would hit the hip joint");
assert(norm([shoulder[0], zcs - shoulder[1]]) > sqrt(head_r*head_r - pow(x_face + limb_gap, 2)) + arm_len + hand_r + 0.5, "arm sweep would hit the head: raise torso_h");

module rrect(size, r, h) { linear_extrude(h) offset(r) offset(-r) square(size, center=true); }
module box(b, z0, z1, g=0) { translate([b[0][0]-g, b[0][1]-g, z0]) cube([b[1][0]-b[0][0]+2*g, b[1][1]-b[0][1]+2*g, z1-z0]); }
module yz_extrude(h) { rotate([90, 0, 90]) linear_extrude(h) children(); }   // 2D (y,z) profile extruded along +X

// pocket frame: origin at the centre of the pocket floor, +Z out of the face,
// +Y toward the top of the face, +X to the right when you look at the robot
module head_frame() { translate(Cs) rotate([90-face_elev, 0, 0]) translate([0, 0, s_floor]) children(); }

// ======================= MOUNT PLATE =======================
module plate() {
    difference() {
        union() {
            hull() { cylinder(r=plate_r - 0.3, h=0.01); translate([0, 0, 0.3]) cylinder(r=plate_r, h=plate_t - 0.3); }
            translate([-lug_w/2, -plate_r - lug_out, 0]) cube([lug_w, 1.5 + lug_out, plate_t]);
        }
        difference() {
            translate([0, 0, plate_t - plate_relief]) cylinder(r=base_d/2 - 1.9, h=plate_relief + 1);
            for (p = holes) translate([p[0], p[1], 0]) cylinder(d=pad_d, h=plate_t + 2);
            if (magnets) for (m = mag_pos) translate([m[0], m[1], 0]) cylinder(d=mag_hole_d + 2.4, h=plate_t + 2);
        }
        for (p = holes) translate([p[0], p[1], 0]) {
            translate([0, 0, -1]) cylinder(d=hole_d, h=plate_t + 2);
            translate([0, 0, -0.01]) cylinder(d=cb_d, h=cb_h);
        }
        intersection() {
            translate([0, 0, -1]) cylinder(r=open_r, h=plate_t + 2);
            union() {
                translate([usb[0], usb[1] + 0.1, -1]) rrect(usb_open, 1.5, plate_t + 2);
                box(hdr, -1, plate_t + 1, 0.6);
                box(urt, -1, plate_t + 1, 0.6);
            }
        }
        if (magnets) for (m = mag_pos)
            translate([m[0], m[1], -0.01]) cylinder(d=mag_hole_d, h=mag_t + mag_recess);
    }
}

// ======================= JOINT PARTS =======================
// Hub pin, drawn as printed: cap on the bed, stem up, square key on top.
module hub() {
    difference() {
        union() {
            hull() { cylinder(r=cap_r - 0.5, h=0.01); translate([0, 0, 0.5]) cylinder(r=cap_r, h=cap_t - 0.5); }
            translate([0, 0, cap_t]) difference() {
                cylinder(r=stem_r, h=stem_len);
                for (k = [0:7]) rotate(22.5 + 45*k) translate([stem_r + notch_off, 0, -1]) cylinder(r=notch_r, h=stem_len + 2, $fn=24);
            }
            translate([0, 0, cap_t + stem_len]) rotate(45) translate([-key_w/2, -key_w/2, 0]) cube([key_w, key_w, key_h]);
        }
        translate([0, 0, -1]) cylinder(d=3.4, h=40);
        translate([0, 0, -0.01]) cylinder(d=6.0, h=hub_cb - 1.3 + 0.02);
        translate([0, 0, hub_cb - 1.3]) cylinder(d1=6.0, d2=3.4, h=1.3);
    }
}
// Split ring with two teeth. Limb axis runs toward -Y, the split is at +Y.
module hub_ring_2d(ring_t) {
    ro = bore_r + ring_t;
    difference() {
        circle(r=ro);
        circle(r=bore_r);
        translate([-split_w/2, 0]) square([split_w, ro + 1]);
    }
    for (s = [-1, 1]) rotate(90 + s*tooth_ang) translate([bore_r + tooth_off, 0]) circle(r=tooth_r, $fn=24);
}
module leg_2d() {
    hub_ring_2d(leg_ring_t);
    difference() {
        union() {
            offset(r=3) offset(delta=-3) union() {
                translate([-leg_ro, -leg_len]) square([2*leg_ro, leg_len - root_b]);
                translate([-leg_ro - foot_len, -leg_len]) square([foot_len + 2, foot_h]);     // foot points toward -X
            }
            translate([leg_ro - 2, -leg_len]) square([2 + heel, 5]);
        }
        circle(r=bore_r);
    }
}
module arm_2d() {
    hub_ring_2d(arm_ring_t);
    difference() {
        hull() {
            translate([-arm_w/2, -root_b - 3]) square([arm_w, 3]);
            translate([0, -arm_len]) circle(r=hand_r);
        }
        circle(r=bore_r);
    }
}
// Extrude a 2D limb with every edge chamfered, top and bottom, in two 0.2 mm steps.
// On the bed side this absorbs first-layer squish; it also opens the bore's mouth.
module limb_3d(t=limb_t) {
    c = edge_ch;
    translate([0, 0, c]) linear_extrude(t - 2*c) children();
    for (i = [0, 1]) {
        d = c*(2 - i)/2;
        translate([0, 0, i*c/2]) linear_extrude(c/2 + 0.001) offset(delta=-d) children();
        translate([0, 0, t - (i + 1)*c/2]) linear_extrude(c/2) offset(delta=-d) children();
    }
}
module leg() { limb_3d() leg_2d(); }
module arm() { limb_3d() arm_2d(); }
// Test piece: three eyes with different ring thickness on one bar (1, 2, 3 notches).
module test_2d() {
    for (i = [0:2]) translate([i*20, 0]) {
        hub_ring_2d(test_rings[i]);
        difference() {
            translate([-8, -root_b - 9]) square([16, 9]);
            circle(r=bore_r);
            for (k = [0:i]) translate([-2*i + 4*k - 0.8, -root_b - 9.01]) square([1.6, 2]);
        }
    }
    translate([-8, -root_b - 9]) square([56, 5]);
}
module test_piece() { limb_3d() test_2d(); }

// place a flat limb on the robot's right side; ang > 0 swings it forward
module on_right(axis, ang) { translate([x_face + limb_gap, axis[0], axis[1]]) rotate([-ang, 0, 0]) rotate([90, 0, 90]) children(); }
module hub_right(axis) { translate([x_face + cap_t + stem_len, axis[0], axis[1]]) rotate([0, -90, 0]) children(); }
module both_sides() { children(); mirror([1, 0, 0]) children(); }

// ======================= BODY =======================
module box_2d(inset=0) {
    translate([0, (box_y[0] + box_y[1])/2]) offset(delta=-inset) offset(r=box_r) offset(delta=-box_r)
        square([2*x_face, box_y[1] - box_y[0]], center=true);
}
module torso_outer() {
    hull() { linear_extrude(0.01) box_2d(0.6); translate([0, 0, 0.6]) linear_extrude(0.01) box_2d(); }   // chamfered bottom edge
    translate([0, 0, 0.6]) linear_extrude(z_n - 0.6) box_2d();
    hull() {                                                                                             // collar: box to the ring the head sits on
        translate([0, 0, z_n - 0.01]) linear_extrude(0.01) box_2d();
        translate([0, 0, z_tt - 0.01]) linear_extrude(0.01) circle(r=collar_r, $fn=160);
    }
}
module head_solid() {
    intersection() {
        translate(Cs) sphere(r=head_r, $fn=160);
        head_frame() translate([-100, -100, -200]) cube([200, 200, 200 + pocket_depth]);
    }
}
module antenna_part() {
    p = Cs + head_r*[0, sin(ant_polar), cos(ant_polar)];
    translate(p - [0, 0, 3]) {
        cylinder(r1=3.4, r2=2.2, h=ant_h + 3);
        translate([0, 0, ant_h + 3]) sphere(r=3.0);
    }
}
module backpack() {
    translate([-bp_w/2, 0, 0]) yz_extrude(bp_w)
        polygon([[bp_y0, 0], [bp_rear, 0], [bp_rear, bp_h], [bp_y0, bp_h + (bp_rear - bp_y0)*roof_t]]);
}
module side_block_2d() {
    hull() { translate(hip) circle(r=hip_r); translate([hip[0] - hip_r, 0]) square([2*hip_r, 0.01]); }
    hull() { translate(shoulder) circle(r=sh_r); translate([shoulder[0] - sh_r, 0]) square([2*sh_r, 0.01]); }
}
module side_blocks() { both_sides() translate([x_in, 0, 0]) yz_extrude(x_face - x_in) side_block_2d(); }
module body_solid() {
    head_solid();
    torso_outer();
    backpack();
    if (antenna) antenna_part();
}
module body_cavity() {
    zr = z_n - roof_drop;                 // the ceiling is a hip roof at roof_ang, so it prints without supports
    ri = box_r - wall;
    d2 = min(x_face, (box_y[1] - box_y[0])/2) - wall - ri - 0.5;
    translate([0, 0, floor_t]) linear_extrude(zr - floor_t + 0.01) box_2d(wall);
    hull() {
        translate([0, 0, zr]) linear_extrude(0.01) box_2d(wall);
        translate([0, 0, zr + ri*roof_t]) linear_extrude(0.01) box_2d(wall + ri);
    }
    hull() {
        translate([0, 0, zr + ri*roof_t]) linear_extrude(0.01) box_2d(wall + ri);
        translate([0, 0, zr + (ri + d2)*roof_t]) linear_extrude(0.01) box_2d(wall + ri + d2);
    }
    translate([-(bp_w/2 - wall), 0, 0]) yz_extrude(bp_w - 2*wall)       // backpack, sloped ceiling
        polygon([[bp_y0, floor_t], [bp_rear - wall, floor_t], [bp_rear - wall, bp_h - 1], [bp_y0, bp_h - 1 + (bp_rear - wall - bp_y0)*roof_t]]);
}
module plug_channel() {
    head_frame() translate([usb[0], usb[1], -chan_len]) rrect(chan, 2, chan_len + 0.01);
}
module head_cuts() {
    head_frame() {
        cylinder(d=pocket_d, h=pocket_depth + 1);
        translate([0, 0, pocket_depth - 0.6]) cylinder(d1=pocket_d, d2=pocket_d + 1.2, h=0.61);
        translate([-(lug_w + 0.6)/2, -(plate_r + lug_out + 0.45), 0])
            cube([lug_w + 0.6, 2 + (plate_r + lug_out + 0.45 - pocket_d/2), pocket_depth + 1]);          // keyway
        for (sx = [-1, 1]) translate([sx > 0 ? 15 : -55, -scallop_w/2, scallop_w0]) cube([40, scallop_w, 60]);   // finger slots
        if (magnets) for (m = mag_pos)
            translate([m[0], m[1], -(mag_t + mag_recess)]) cylinder(d=mag_hole_d, h=mag_t + mag_recess + 0.01);
    }
    plug_channel();
}
module chest_ring() {      // shallow ring on the flat front
    translate([0, box_y[0] - 1, 18]) rotate([-90, 0, 0]) difference() {
        cylinder(d=14, h=1.8);
        translate([0, 0, -1]) cylinder(d=8.5, h=4);
    }
}
module joint_cuts() {          // diamond key recess and pilot hole for each hub
    rw = (key_w + 2*key_clear)/sqrt(2);
    both_sides() for (ax = [hip, shoulder]) translate([0, ax[0], ax[1]]) {
        translate([x_face - key_h - 0.4, 0, 0]) yz_extrude(key_h + 1.4) polygon([[0, rw], [rw, 0], [0, -rw], [-rw, 0]]);
        translate([x_face - key_h - 0.4 - pilot_len, 0, 0]) rotate([0, 90, 0]) cylinder(d=pilot_d, h=pilot_len + 1);
    }
}
module body() {
    difference() {
        union() {
            difference() { body_solid(); body_cavity(); }
            side_blocks();
        }
        head_cuts();
        chest_ring();
        joint_cuts();
        translate([0, bottom_open_y, -1]) rrect(bottom_open, 5, floor_t + 2);                 // threading opening
        translate([-slot_w/2, bottom_open_y, -1]) cube([slot_w, 100, floor_t + 1.01]);        // cable channel in the floor
        translate([0, bp_rear - wall - 1, 0]) rotate([90, 0, 0]) translate([0, 0, -(wall + 2)]) linear_extrude(wall + 2)
            polygon([[-slot_w/2, -1], [slot_w/2, -1], [slot_w/2, slot_h], [grip_top/2, grip_h], [-grip_top/2, grip_h], [-slot_w/2, slot_h]]);
        translate([-100, -100, -50]) cube([200, 200, 50]);
    }
}

// ======================= SEAT =======================
// Drawn in robot coordinates with the robot locked: seat top on Z = 0.
module open_2d(d=0) { translate([0, bottom_open_y]) offset(delta=d) offset(r=5) offset(delta=-5) square(bottom_open, center=true); }
isl_front = bottom_open_y - bottom_open[1]/2 + isl_clear;
module island_2d() { intersection() { open_2d(-isl_clear); translate([-50, isl_front - 1]) square([100, isl_len + 1]); } }
module island_front_2d() { intersection() { island_2d(); translate([-50, isl_front - 1]) square([100, 3.5]); } }
module seat_lip_2d() { intersection() { offset(r=lip) island_front_2d(); translate([-50, isl_front - lip - 1]) square([100, lip + 3.5]); } }
pin_k = (5 - pin_d/2 - pin_clear)*sqrt(0.5);
pin_pos = [for (sx = [-1, 1]) [sx*(bottom_open[0]/2 - 5 + pin_k), bottom_open_y + bottom_open[1]/2 - 5 + pin_k]];
module seat_top_features() {
    linear_extrude(isl_h) island_2d();
    hull() {                                           // hook with a 45 degree underside
        translate([0, 0, floor_t + lip_gap]) linear_extrude(0.01) island_front_2d();
        translate([0, 0, floor_t + lip_gap + lip]) linear_extrude(isl_h - floor_t - lip_gap - lip) seat_lip_2d();
    }
    for (p = pin_pos) translate([p[0], p[1], 0]) {
        cylinder(d=pin_d, h=pin_h - 0.3);
        translate([0, 0, pin_h - 0.3]) cylinder(d1=pin_d, d2=pin_d - 0.6, h=0.3);
    }
}
module seat_outline() { translate([0, (seat_y[0] + seat_y[1])/2]) offset(r=seat_r) square([seat_w - 2*seat_r, seat_y[1] - seat_y[0] - 2*seat_r], center=true); }
module seat() {
    seat_top_features();
    translate([0, 0, -seat_t]) difference() {
        hull() {
            linear_extrude(seat_t - seat_ch) seat_outline();
            translate([0, 0, seat_t - 0.01]) linear_extrude(0.01) offset(delta=-seat_ch) seat_outline();
        }
        for (p = seat_keyholes) translate([p[0], p[1], 0]) {
            translate([0, 0, -1]) cylinder(d=skey_head, h=skey_skin + 2);
            hull() for (dy = [0, -skey_len]) translate([0, dy, -1]) cylinder(d=skey_slot, h=skey_skin + 2);
            hull() for (dy = [0, -skey_len]) translate([0, dy, skey_skin]) cylinder(d=skey_head, h=skey_depth);
        }
        translate([-seat_groove[0]/2, seat_groove[2], seat_t - seat_groove[1]]) cube([seat_groove[0], 100, seat_groove[1] + 1]);
    }
}

// ======================= GHOSTS (preview and checks only) =======================
module display_ghost() {
    translate([0, 0, plate_t]) {
        color("silver", 0.5) cylinder(d=base_d, h=base_h);
        color("#222", 0.6) translate([0, 0, base_h]) cylinder(d=cover_d, h=cover_h);
        color("gold") translate([usb[0], usb[1], -conn_protrude]) rrect([9.2, 3.4], 1.2, conn_protrude);
        intersection() {
            translate([0, 0, -conn_protrude]) cylinder(r=20.1, h=conn_protrude);
            union() { color("green") box(hdr, -conn_protrude, 0); color("white") box(urt, -conn_protrude, 0); }
        }
    }
}
module plug_ghost(cable=30) {
    z1 = plate_t - conn_protrude - 0.45;
    color("dimgray") translate([usb[0], usb[1], plate_t - plug_len]) rrect([12.3, 6.5], 2, z1 - (plate_t - plug_len));
    color("#444") translate([usb[0], usb[1], plate_t - plug_len - cable]) cylinder(d=4.5, h=cable);
}
module magnets_ghost() {
    if (magnets) for (m = mag_pos) {
        color("silver") translate([m[0], m[1], mag_recess]) cylinder(d=6, h=mag_t);
        color("silver") translate([m[0], m[1], -mag_recess - mag_t]) cylinder(d=6, h=mag_t);
    }
}
module limbs(leg_ang, arm_ang) {
    both_sides() {
        color("#5a6270") on_right(hip, leg_ang) leg();
        color("#5a6270") on_right(shoulder, arm_ang) arm();
        color("#f2a03d") hub_right(hip) hub();
        color("#f2a03d") hub_right(shoulder) hub();
    }
}
module robot(leg_ang, arm_ang, lift) {
    translate([0, 0, lift]) {
        color("#f2a03d") body();
        limbs(leg_ang, arm_ang);
        head_frame() color("#8090a8") plate();
        if (show_ghosts) head_frame() { display_ghost(); plug_ghost(); magnets_ghost(); }
    }
}

// ======================= OUTPUT =======================
if (part == "body") body();
else if (part == "leg") leg();
else if (part == "arm") arm();
else if (part == "hub") hub();
else if (part == "plate") plate();
else if (part == "seat") translate([0, 0, seat_t]) seat();
else if (part == "test") { plate(); translate([36, -8, 0]) hub(); translate([-20, 36, 0]) test_piece(); }
else if (part == "assembly") {
    if (pose == "stand") robot(0, arm_pose, stand_lift);
    else {
        robot(90, arm_pose, 0);
        if (on_seat) color("#5a6270") seat();
    }
}
