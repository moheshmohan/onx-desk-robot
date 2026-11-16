// ---------------------------------------------------------------
// One-piece desk robot for the ONX2424G013 (Open Nextion 1.28" round knob display)
// The display is the robot's face. The robot sits: legs forward, hands on the desk.
// Nothing moves, nothing is assembled. Units: mm. Front of the robot = -Y.
//
//   part = "print"    : the whole print job: robot and mount plate side by side
//   part = "robot"    : the robot alone (print standing, no supports)
//   part = "plate"    : the mount plate alone (screwed to the back of the display)
//   part = "seat"     : optional desk seat the robot slides onto and locks
//   part = "assembly" : preview with the display, plug and cable shown
//
// Export:  openscad -D 'part="print"' -o robot_onepiece_print.stl onx2424g013_robot_onepiece.scad
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
// ---------------------------------------------------------------

part = "assembly";   // [print, robot, plate, seat, assembly]
on_seat = false;     // show the seat under the robot in the preview

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
plate_t      = 3.2;   // a thicker plate lifts the knob further off the rim
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
head_r     = 30;
face_r     = 26;      // flat face ring around the knob
face_elev  = 50;      // degrees the face looks up from horizontal. 50 keeps the pocket roof at a 40 degree overhang
neck_polar = 50;      // the ball is buried in the collar up to this angle from its bottom (40 degree overhang above it)
roof_ang   = 50;      // slope of the collar, the body's inner ceiling and the backpack roof, from horizontal
chan       = [16, 9.5];   // plug channel. Rugged plugs reach 13.5 x 7.5
chan_len   = 24;
plug_len   = 25;      // USB-C plug length from the display's back plane to the end of the overmold
scallop_w  = 18;      // finger slots left and right of the pocket
scallop_w0 = 1.0;
antenna    = false;   // true adds a thin pin on top of the head: 11 mm more print height and the one fragile feature
ant_polar  = 36;
ant_h      = 13;

/* [Body] */
torso_h  = 26;         // low torso: short print, and a knob press lands inside the footprint
box_y    = [-20, 28];  // torso: a rounded box. Front and rear face; its flat sides are at +-x_face
box_r    = 10;         // corner radius, seen from above
x_face   = 23.1;       // just over head_r*sin(neck_polar), so the torso itself supports the head at the sides
roof_drop = 8;         // the inner ceiling starts this far below the top of the torso
wall     = 1.8;         // four 0.45 mm lines: prints as walls only, no gap fill
bp_wall  = 2.4;         // the backpack keeps a thicker wall: its rear wall is the cable grip
floor_t  = 2.0;
bp_w     = 26;        // backpack: cable exit and rear support
bp_y0    = 20;
bp_rear  = 40;
bp_h     = 8;
slot_w   = 7;         // cable slot in the backpack's rear wall, open at the bottom
slot_h   = 2.5;       // straight part; above it the slot tapers so the cable can be pressed up and gripped
grip_top = 2.2;       // width at the top of the taper
grip_h   = 10;
bottom_open = [18, 28];   // opening in the floor for threading the plug
bottom_open_y = 6;

/* [Fixed limbs] */
// Legs lie on the bed and arms stand on it, so neither has an overhang.
leg_x    = 11.5;      // leg centre line
leg_w    = 11;
leg_h    = 9;
leg_r    = 3.5;
leg_len  = 19;        // front of the torso to the sole
foot_t   = 6;
foot_w   = 12.5;
foot_h   = 14.5;
foot_r   = 4;
arm_t    = 6.5;       // how far the arm stands off the torso's side
arm_sh   = [5, 17.5]; // shoulder centre: y, z
arm_r    = 6;
arm_hand = [-9, 2];   // the hand's contact with the desk, front and rear y
arm_ch   = 1.2;       // chamfer on the arm's outer face and the foot's sole
bed_ch   = 0.6;       // chamfer on edges that touch the bed, against first-layer squish

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
sole_y = box_y[0] - leg_len;
print_h = max(zcs + head_r, antenna ? zcs + head_r*cos(ant_polar) + ant_h + 3 : 0);

echo(str("ROBOT: ball centre z ", zcs, "  knob centre ", knob_c, "  top of knob z ", knob_c[2] + cover_d/2*cos(face_elev)));
echo(str("ROBOT: print height ", print_h, "  footprint x +-", x_face + arm_t, "  y ", sole_y, " .. ", bp_rear));
echo(str("ROBOT: knob press line meets the desk at y = ", press_hit_y, "  backpack rear edge y = ", bp_rear));
assert(face_elev >= 45 && roof_ang >= 45, "below 45 degrees needs supports");
assert(plate_r + lug_out + 0.45 < cover_d/2, "keyway would show past the knob");
assert(x_face >= collar_r, "torso narrower than the collar: the head would overhang at the sides");
assert(arm_sh[1] + arm_r < torso_h, "shoulder would rise above the flat side of the torso");
assert(arm_hand[0] > box_y[0] + box_r && arm_sh[0] + arm_r < box_y[1] - box_r, "arm would leave the flat side of the torso");
assert(leg_x + leg_w/2 < x_face - 1, "legs wider than the torso");

module rrect(size, r, h) { linear_extrude(h) offset(r) offset(-r) square(size, center=true); }
module box(b, z0, z1, g=0) { translate([b[0][0]-g, b[0][1]-g, z0]) cube([b[1][0]-b[0][0]+2*g, b[1][1]-b[0][1]+2*g, z1-z0]); }
module yz_extrude(h) { rotate([90, 0, 90]) linear_extrude(h) children(); }   // 2D (y,z) profile extruded along +X
module xz_extrude(h) { rotate([90, 0, 0]) linear_extrude(h) children(); }    // 2D (x,z) profile extruded along -Y
module both_sides() { children(); mirror([1, 0, 0]) children(); }

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

// ======================= ROBOT =======================
module box_2d(inset=0) {
    translate([0, (box_y[0] + box_y[1])/2]) offset(delta=-inset) offset(r=box_r) offset(delta=-box_r)
        square([2*x_face, box_y[1] - box_y[0]], center=true);
}
module torso_outer() {
    hull() { linear_extrude(0.01) box_2d(bed_ch); translate([0, 0, bed_ch]) linear_extrude(0.01) box_2d(); }   // chamfered bottom edge
    translate([0, 0, bed_ch]) linear_extrude(z_n - bed_ch) box_2d();
    hull() {                                                                                                   // collar: box to the ring the head sits on
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
// Limb cross-section standing on the bed: flat bottom with a small chamfer, rounded top.
// inset shrinks the sides and the top but keeps the bottom on the bed.
module limb_prof(w, h, r, inset=0) {
    hull() {
        translate([-(w/2 - inset) + bed_ch, 0]) square([w - 2*inset - 2*bed_ch, 0.01]);
        translate([-(w/2 - inset), bed_ch]) square([w - 2*inset, 0.01]);
        for (s = [-1, 1]) translate([s*(w/2 - r), h - r]) circle(r=r - inset);
    }
}
module legs() {
    both_sides() translate([leg_x, 0, 0]) {
        translate([0, box_y[0] + 1.7, 0]) xz_extrude(leg_len + 1.7) limb_prof(leg_w, leg_h, leg_r);
        hull() {                                                   // foot: sole forward, toes up
            translate([0, sole_y + foot_t, 0]) xz_extrude(foot_t - arm_ch) limb_prof(foot_w, foot_h, foot_r);
            translate([0, sole_y + 0.01, 0]) xz_extrude(0.01) limb_prof(foot_w, foot_h, foot_r, arm_ch);
        }
    }
}
module arm_prof(inset=0) {      // (y, z): shoulder disc on the torso's side, hand flat on the desk
    hull() {
        translate(arm_sh) circle(r=arm_r - inset);
        translate([arm_hand[0] + inset + bed_ch, 0]) square([arm_hand[1] - arm_hand[0] - 2*inset - 2*bed_ch, 0.01]);
        translate([arm_hand[0] + inset, bed_ch]) square([arm_hand[1] - arm_hand[0] - 2*inset, 0.01]);
    }
}
module arms() {
    both_sides() hull() {
        translate([x_face - 1, 0, 0]) yz_extrude(arm_t + 1 - arm_ch) arm_prof();
        translate([x_face + arm_t - 0.01, 0, 0]) yz_extrude(0.01) arm_prof(arm_ch);
    }
}
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
    translate([-(bp_w/2 - bp_wall), 0, 0]) yz_extrude(bp_w - 2*bp_wall)       // backpack, sloped ceiling
        polygon([[bp_y0, floor_t], [bp_rear - bp_wall, floor_t], [bp_rear - bp_wall, bp_h - 1], [bp_y0, bp_h - 1 + (bp_rear - bp_wall - bp_y0)*roof_t]]);
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
module chest_ring() {      // shallow ring on the flat front, between the legs
    translate([0, box_y[0] - 1, (leg_h + torso_h)/2 - 2.5]) rotate([-90, 0, 0]) difference() {
        cylinder(d=11.5, h=1.6);
        translate([0, 0, -1]) cylinder(d=6.5, h=4);
    }
}
module body() {
    difference() {
        union() {
            difference() { body_solid(); body_cavity(); }
            legs();
            arms();
        }
        head_cuts();
        chest_ring();
        translate([0, bottom_open_y, -1]) rrect(bottom_open, 5, floor_t + 2);                 // threading opening
        translate([-slot_w/2, bottom_open_y, -1]) cube([slot_w, 100, floor_t + 1.01]);        // cable channel in the floor
        translate([0, bp_rear - bp_wall - 1, 0]) rotate([90, 0, 0]) translate([0, 0, -(bp_wall + 2)]) linear_extrude(bp_wall + 2)
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
module plug_ghost(cable=30, len=plug_len) {
    z1 = plate_t - conn_protrude - 0.45;
    color("dimgray") translate([usb[0], usb[1], plate_t - len]) rrect([12.3, 6.5], 2, z1 - (plate_t - len));
    color("#444") translate([usb[0], usb[1], plate_t - len - cable]) cylinder(d=4.5, h=cable);
}
module magnets_ghost() {
    if (magnets) for (m = mag_pos) {
        color("silver") translate([m[0], m[1], mag_recess]) cylinder(d=6, h=mag_t);
        color("silver") translate([m[0], m[1], -mag_recess - mag_t]) cylinder(d=6, h=mag_t);
    }
}

// ======================= OUTPUT =======================
plate_at = [x_face + arm_t + 8 + plate_r + lug_out, 0, 0];
if (part == "robot") body();
else if (part == "plate") plate();
else if (part == "print") { body(); translate(plate_at) rotate(90) plate(); }
else if (part == "seat") translate([0, 0, seat_t]) seat();
else if (part == "assembly") {
    color("#f2a03d") body();
    head_frame() color("#8090a8") plate();
    if (show_ghosts) head_frame() { display_ghost(); plug_ghost(); magnets_ghost(); }
    if (on_seat) color("#5a6270") seat();
}
