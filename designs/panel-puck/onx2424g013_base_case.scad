// ---------------------------------------------------------------
// ONX2424G013 (Open Nextion 1.28" round knob display) + CC1101 433 MHz radio
//   part = "stand"    : hollow tilted desk stand (shell). Holds the module on top,
//                       the CC1101 inside, SMA jack out through the left side wall
//   part = "base"     : screw-on bottom plate of the stand (keyholes, feet, radio clip)
//   part = "case"     : flat puck for panel / wall mounting (no radio room)
//   part = "assembly" : stand + base + ghosts of the module and the radio (preview)
// Export:  openscad -D 'part="stand"' -o onx2424g013_stand.stl onx2424g013_base_case.scad
// Units: mm.  Print "stand" and "base" as exported (flat side down), no supports.
//
// Module geometry (Nextion dimension drawing + product photo of the back):
//   Rotating top cover .... D48.0 x 17.0 tall  (this is the knob, it also presses)
//   Fixed bottom cover .... D43.27, 8.4 tall, open at the back, PCB recessed inside
//   Rim + 3 screw bosses .. flush with the back plane; M1.6 nuts in the bosses
//   Connectors on back .... protrude 2.6 beyond the back plane, all axial:
//                           USB-C, J4 2x4 female header (2.54), J5 4-pin 1.25 (5V0 TX RX GND)
//
// Only the D43.27 base may touch the print. The D48 knob overhangs it by 2.37
// per side and must stay free: nothing may touch its side or its underside.
// ---------------------------------------------------------------

part = "assembly";   // [stand, base, case, assembly]

/* [Module (do not change unless you measured otherwise)] */
base_d        = 43.27;
base_h        = 8.4;
cover_d       = 48.0;
cover_h       = 17.0;
conn_protrude = 2.6;
// Positions below are as seen LOOKING AT THE BACK of the module, exactly as in
// Nextion's drawing (hole_template.pdf checks them at 1:1).
// A part that mates with the back sees the MIRROR IMAGE of that view, so every
// printable part is mirrored left-to-right at output (mirror_fix). The first
// versions of this file missed that; keep mirror_fix = true.
mirror_fix = true;
holes      = [[-16.90, 0], [8.60, 14.72], [9.11, -14.42]];   // 3x M1.6
usb_pos    = [-11.0, 0];                                     // USB-C centre, long side along Y
header_box = [[-5.5, -18.5], [6.5, -7.5]];                   // J4 2x4 header, [x0,y0],[x1,y1]
uart_box   = [[13.5, -10.0], [19.6, 1.5]];                   // J5 4-pin 1.25 connector

/* [Fit and clearances] */
radial_clear = 0.5;   // gap between base OD and pocket wall (FDM: 0.4-0.6)
press_gap    = 1.5;   // pocket rim stays this far below the knob underside
                      // (must exceed the push travel; measure yours, ~0.5-1 mm)
hole_d       = 2.1;   // through hole for M1.6
driver_d     = 4.0;   // driver access channel behind each M1.6 screw
plate_solid  = 2.0;   // material the M1.6 screw passes through -> M1.6 x 4 or x 5
usb_hole     = [8.0, 14.0];   // USB-C plug overmold envelope, X x Y
usb_hole_r   = 2.0;

/* [Puck (panel mount)] */
wall           = 2.0;   // pocket wall. 2.0 -> puck OD 48.27, flush with the knob
floor_t        = 2.5;
cavity_h       = 4.0;
cavity_d       = 38.0;
panel_mount    = true;
panel_boss_pos = [[12, 6], [-12, -11]];
panel_boss_d   = 7.0;
panel_screw_d  = 2.6;
cable_slot     = false;
cable_slot_w   = 9.0;
cable_slot_h   = 5.0;
cable_angle    = 270;
usb_floor_hole = true;

/* [Stand shell] */
tilt          = 30;     // degrees from horizontal
stand_margin  = [4, 4, 7];   // flat surface around the pocket: front, sides, rear
h_front_min   = 12;     // front height (raised automatically for the plug and wires)
shell_wall    = 2.4;    // side, front and rear walls
top_t         = 2.4;    // inclined top plate
r_open        = 19.5;   // opening under the module; the ledge outside it carries the rim
cup_wall      = 2.0;    // wall around the pocket
saw_p         = 8;      // pitch of the 45-degree ridges that make the inner ceiling printable
plug_len      = 25;     // USB-C plug length measured from the module's back plane
dupont_len    = 14;     // Dupont housing length on the jumpers plugged into J4
wire_bend     = 6;      // room under plug / Dupont ends for the wires to bend
cable_notch   = [-15, 10, 7];   // rear cable exit: x centre, width, height

/* [Stand base plate] */
base_t         = 3.0;
base_screw_pos = [[-22, -17.5], [22, -17.5], [-22, 12], [22, 12]];  // 4x M3 into the shell
base_boss_d    = 7.0;
base_boss_h    = 12;
base_pilot_d   = 2.6;   // M3 self-tapping. Use 4.0 for M3 heat-set inserts
base_screw_d   = 3.4;
base_cs_d      = 6.8;   // countersink for M3 flat head
foot_d         = 9.5;   // stick-on foot recess, covers the screw head
foot_depth     = 0.6;
keyhole_pos    = [[-12.5, -6], [12.5, -6], [12, 10]];  // entry hole; slot runs toward the front
keyhole_len    = 9;
keyhole_head_d = 8.0;   // #6 / M3.5 pan head
keyhole_slot_w = 4.4;
keyhole_skin   = 2.0;
keyhole_depth  = 3.0;   // head pocket height (pan head ~2.4-2.8)
keyhole_pad_d  = 11;    // raised pad around each keyhole

/* [CC1101 radio (E07-M1101D style board)] */
radio        = true;
rf_board     = [30, 16.5, 1.6];  // length (SMA edge to header end), width, thickness. MEASURE YOURS
rf_comp_h    = 2.0;    // tallest part on the component side
rf_flange    = [7.0, 2.0];       // SMA square flange: size, thickness
rf_sma_len   = 9.0;    // SMA from board edge to thread tip
rf_sma_d     = 6.7;    // hole for the 1/4-36 (6.35) thread
rf_sma_off   = 0.8;    // SMA axis offset from board mid-plane toward the component side
rf_skin      = 1.6;    // wall in front of the flange (thread exposed = len - flange - skin)
rf_z         = 16;     // SMA axis height above the desk
rf_rear_gap  = 3.0;    // component side to rear wall
rf_keeper    = 1.2;    // wall behind the flange (stops the jack being pushed in)
antenna      = [50, 7];          // preview only: length, diameter

/* [Preview] */
show_module = true;
$fn = 96;

// ---------------- derived: common ----------------
pocket_d     = base_d + 2*radial_clear;
pocket_depth = base_h - press_gap;
outer_d      = pocket_d + 2*wall;
ledge_t      = plate_solid;
s_t = sin(tilt); c_t = cos(tilt);

// ---------------- derived: puck ----------------
z_base_bot   = floor_t + cavity_h;
z_conn_face  = z_base_bot - conn_protrude;
case_h       = z_base_bot + pocket_depth;

// ---------------- derived: stand ----------------
v_front  = pocket_d/2 + wall + stand_margin[0];
v_rear   = pocket_d/2 + wall + stand_margin[2];
W        = pocket_d + 2*wall + 2*stand_margin[1];
y_front  = -v_front*c_t;
y_rear   =  v_rear*c_t;
D        = y_rear - y_front;
R_cup    = pocket_d/2 + cup_wall;
hb_c     = (header_box[0] + header_box[1])/2;
// incline centre height needed so the USB plug and the J4 Dupont housings clear the base plate
zc_plug  = base_t + max(1 + (usb_hole[1]/2 - 0.8)*s_t, wire_bend)
           + (pocket_depth + plug_len)*c_t - usb_pos[1]*s_t;
zc_dup   = base_t + wire_bend + 2.6*s_t
           + (pocket_depth + conn_protrude + dupont_len)*c_t - hb_c[1]*s_t;
zc       = max(h_front_min + v_front*s_t, zc_plug, zc_dup);
h_front  = zc - v_front*s_t;
h_rear   = zc + v_rear*s_t;

// ---------------- derived: radio ----------------
x_edge   = W/2 - rf_skin - rf_flange[1];          // board edge = inner face of the SMA flange
x_in     = x_edge - rf_board[0];                  // header end of the board
y_bc     = y_rear - shell_wall - rf_rear_gap;     // component face of the board
y_b      = y_bc - rf_board[2]/2;                  // board mid-plane
y_s      = y_b + rf_sma_off;                      // SMA axis
z_s      = rf_z;
thread_out = rf_sma_len - rf_flange[1] - rf_skin;

echo(str("PUCK: OD ", outer_d, " height ", case_h, " rim gap ", press_gap));
echo(str("STAND: footprint ", round(W*10)/10, " x ", round(D*10)/10, " front ", round(h_front*10)/10,
         " rear ", round(h_rear*10)/10, "  incline centre z ", round(zc*10)/10));
echo(str("RADIO: board x ", round(x_in*10)/10, "..", round(x_edge*10)/10, "  y ", round(y_b*10)/10,
         "  SMA axis z ", z_s, "  thread exposed ", thread_out, " mm"));
assert(plate_solid < conn_protrude, "plate_solid must be below conn_protrude");
assert(!radio || thread_out >= 4.5, "too little SMA thread outside the wall for the antenna nut");
assert(!radio || z_s - rf_board[1]/2 > base_t + 2, "radio board too low: raise rf_z");

module rrect(size, r, h) { linear_extrude(h) offset(r) offset(-r) square(size, center=true); }
module box(b, z0, z1) { translate([b[0][0], b[0][1], z0]) cube([b[1][0]-b[0][0], b[1][1]-b[0][1], z1-z0]); }

// ghost of the module with its back plane at z = 0, including what plugs into it
module module_ghost() {
    color("silver", 0.35) cylinder(d=base_d, h=base_h);
    color("black", 0.35)  translate([0,0,base_h]) cylinder(d=cover_d, h=cover_h);
    color("gold", 0.5)    translate([usb_pos[0], usb_pos[1], -conn_protrude]) rrect([4.6, 9.4], 1.5, conn_protrude);
    color("dimgray", 0.5) translate([usb_pos[0], usb_pos[1], -plug_len]) rrect([6.5, 12.3], 2, plug_len - conn_protrude);
    color("green", 0.35)  box(header_box, -conn_protrude, 0);
    color("white", 0.35)  box(uart_box, -conn_protrude, 0);
    // male Dupont housings in J4 (4 x 2 block) and the 1.25 mm plug in J5
    color("#555", 0.5) translate([hb_c[0], hb_c[1], -conn_protrude - dupont_len/2]) cube([10.4, 5.2, dupont_len], center=true);
    color("#ddd", 0.5) translate([(uart_box[0][0]+uart_box[1][0])/2, (uart_box[0][1]+uart_box[1][1])/2, -conn_protrude - 3])
        cube([3.4, 6.2, 6], center=true);
}

// ======================= PUCK (panel mount) =======================
module case_body() {
    difference() {
        hull() {
            translate([0,0,0.8]) cylinder(d=outer_d, h=case_h-0.8);
            cylinder(d=outer_d-1.6, h=0.8);
        }
        translate([0,0,z_base_bot]) cylinder(d=pocket_d, h=pocket_depth+1);
        translate([0,0,floor_t]) cylinder(d=cavity_d, h=cavity_h+0.01);
        if (cable_slot)
            rotate([0,0,cable_angle])
                translate([outer_d/2 - wall - 6, -cable_slot_w/2, floor_t])
                    cube([wall + 12, cable_slot_w, cable_slot_h]);
        translate([0,0,case_h-0.6]) cylinder(d1=pocket_d, d2=pocket_d+1.2, h=0.61);
    }
    for (p = holes) translate([p[0], p[1], floor_t-0.01]) cylinder(d=6, h=cavity_h+0.02);
    if (panel_mount)
        for (p = panel_boss_pos) translate([p[0], p[1], floor_t-0.01]) cylinder(d=panel_boss_d, h=cavity_h+0.02);
}
module case_cuts() {
    for (p = holes) translate([p[0], p[1], 0]) {
        translate([0,0,-1]) cylinder(d=hole_d, h=z_base_bot+2);
        translate([0,0,-1]) cylinder(d=driver_d, h=z_base_bot - plate_solid + 1);
    }
    if (usb_floor_hole)
        translate([usb_pos[0], usb_pos[1], -1]) rrect(usb_hole, usb_hole_r, z_conn_face + 1);
    if (panel_mount)
        for (p = panel_boss_pos) translate([p[0], p[1], -1]) cylinder(d=panel_screw_d, h=z_base_bot+2);
}
module base_case() { difference() { case_body(); case_cuts(); } }

// ======================= STAND =======================
// incline frame: origin at the centre of the tilted top surface, +y up the slope, +z outward
module incline() { translate([0,0,zc]) rotate([tilt,0,0]) children(); }

module wedge() {
    hull() {
        incline() translate([-W/2, -v_front, -0.01]) cube([W, v_front+v_rear, 0.01]);
        translate([-W/2, y_front, 0]) cube([W, D, 0.01]);
    }
}

// Region below the plane w = U (incline frame) with 45-degree ridges running up the
// slope. A flat ceiling parallel to the 30-degree incline cannot be printed; ridges
// like these give ~52-degree faces in world space, which print without supports.
module saw_below(U) {
    n = ceil(80/saw_p);
    pts = concat([[-n*saw_p, U-200]],
                 [for (i=[-2*n:2*n]) [i*saw_p/2, U - (i%2==0 ? 0 : saw_p/2)]],
                 [[n*saw_p, U-200]]);
    rotate([90,0,0]) linear_extrude(height=200, center=true) polygon(pts);
}

module cavity() {
    intersection() {
        translate([-W/2+shell_wall, y_front+shell_wall, -1]) cube([W-2*shell_wall, D-2*shell_wall, 200]);
        incline() union() {
            difference() { saw_below(-top_t); cylinder(r=R_cup, h=400, center=true); }
            intersection() { saw_below(-(pocket_depth+ledge_t)); cylinder(r=R_cup, h=400, center=true); }
            difference() {                               // opening under the module
                translate([0,0,-150]) cylinder(r=r_open, h=150-pocket_depth+0.01);
                for (p = holes) translate([p[0], p[1], -pocket_depth-ledge_t]) cylinder(d=6, h=ledge_t+0.02);
            }
            box(header_box, -150, -pocket_depth+0.01);   // J4 jumpers pass the ledge
            box(uart_box,   -150, -pocket_depth+0.01);   // J5 pigtail passes the ledge
        }
    }
}

// Local wall thickening that captures the SMA flange. The flange and the thread
// slide UP into slots that are open at the bottom; the base plate's tongue then
// closes them from below. Captured in all directions, so screwing the antenna on
// and off loads the plastic, not the CC1101's solder joints.
module pilaster() {
    y0 = y_s - rf_flange[0]/2 - 2.0;
    translate([x_edge - rf_keeper, y0, base_t - 0.01])
        cube([W/2 - (x_edge - rf_keeper) - 0.01, y_rear - shell_wall + 0.5 - y0, z_s + rf_flange[0]/2 + 2.5 - base_t]);
}
module sma_cuts() {
    fl = rf_flange[0]; t = rf_board[2];
    // flange slot, open at the bottom
    translate([x_edge - 0.05, y_s - fl/2 - 0.2, base_t - 1]) cube([rf_flange[1] + 0.2, fl + 0.4, z_s + fl/2 + 0.2 - base_t + 1]);
    // slit in the keeper wall for the board and the SMA solder legs
    translate([x_edge - rf_keeper - 1, y_b - t/2 - 0.8, base_t - 1]) cube([rf_keeper + 1.1, t + 1.6, 100]);
    // thread slot through the skin, round top, open at the bottom
    hull() {
        translate([x_edge + rf_flange[1], y_s, z_s]) rotate([0,90,0]) cylinder(d=rf_sma_d, h=20);
        translate([x_edge + rf_flange[1], y_s, base_t - 1]) rotate([0,90,0]) cylinder(d=rf_sma_d, h=20);
    }
}
// tongue on the base plate: fills both slots below the flange and the thread
module sma_tongue() {
    fl = rf_flange[0];
    translate([x_edge + 0.15, y_s - fl/2 - 0.05, base_t - 0.01])
        cube([rf_flange[1] - 0.15, fl + 0.1, z_s - fl/2 - 0.25 - base_t]);
    difference() {
        translate([x_edge + rf_flange[1] + 0.05, y_s - rf_sma_d/2 + 0.15, base_t - 0.01])
            cube([W/2 - x_edge - rf_flange[1] - 0.15, rf_sma_d - 0.3, z_s - base_t]);
        translate([x_edge, y_s, z_s]) rotate([0,90,0]) cylinder(d=6.35 + 0.5, h=20);
    }
}

module shell() {
    difference() {
        union() {
            difference() {
                intersection() { wedge(); translate([-W, y_front-1, base_t]) cube([2*W, D+2, 200]); }
                cavity();
            }
            for (p = base_screw_pos) translate([p[0], p[1], base_t-0.01]) cylinder(d=base_boss_d, h=base_boss_h);
            if (radio) pilaster();
        }
        incline() {
            translate([0,0,-pocket_depth]) cylinder(d=pocket_d, h=pocket_depth+1);          // pocket
            translate([0,0,-0.6]) cylinder(d1=pocket_d, d2=pocket_d+1.2, h=0.61);          // lead-in
            for (p = holes) translate([p[0], p[1], 0]) {
                translate([0,0,-pocket_depth-ledge_t-0.5]) cylinder(d=hole_d, h=ledge_t+1);
                translate([0,0,-pocket_depth-ledge_t-150]) cylinder(d=driver_d, h=150);   // driver line
            }
        }
        for (p = base_screw_pos) translate([p[0], p[1], base_t-1]) cylinder(d=base_pilot_d, h=base_boss_h);
        translate([cable_notch[0]-cable_notch[1]/2, y_rear-shell_wall-1, base_t-1])
            cube([cable_notch[1], shell_wall+2, cable_notch[2]+1]);
        if (radio) sma_cuts();
    }
}

module base_plate() {
    pad_h = keyhole_skin + keyhole_depth + 1.2;
    difference() {
        union() {
            translate([-W/2, y_front, 0]) cube([W, D, base_t]);
            for (p = keyhole_pos) hull() {
                translate([p[0], p[1], 0]) cylinder(d=keyhole_pad_d, h=pad_h);
                translate([p[0], p[1]-keyhole_len, 0]) cylinder(d=keyhole_pad_d, h=pad_h);
            }
            if (radio) sma_tongue();
        }
        for (p = keyhole_pos) translate([p[0], p[1], 0]) {
            translate([0,0,-1]) cylinder(d=keyhole_head_d, h=keyhole_skin+2);
            hull() {
                translate([0,0,-1]) cylinder(d=keyhole_slot_w, h=keyhole_skin+2);
                translate([0,-keyhole_len,-1]) cylinder(d=keyhole_slot_w, h=keyhole_skin+2);
            }
            hull() {
                translate([0,0,keyhole_skin]) cylinder(d=keyhole_head_d, h=keyhole_depth);
                translate([0,-keyhole_len,keyhole_skin]) cylinder(d=keyhole_head_d, h=keyhole_depth);
            }
        }
        for (p = base_screw_pos) translate([p[0], p[1], 0]) {
            translate([0,0,-1]) cylinder(d=base_screw_d, h=base_t+2);
            translate([0,0,-1]) cylinder(d=foot_d, h=1+foot_depth);
            translate([0,0,foot_depth-0.01]) cylinder(d1=base_cs_d, d2=base_screw_d, h=(base_cs_d-base_screw_d)/2);
        }
    }
}

module rf_ghost(with_antenna=true) {
    L = rf_board[0]; w = rf_board[1]; t = rf_board[2]; fl = rf_flange[0];
    color("royalblue", 0.7) translate([x_in, y_b - t/2, z_s - w/2]) cube([L, t, w]);
    color("#222", 0.6) translate([x_in + 6, y_b + t/2, z_s - 5]) cube([16, rf_comp_h, 10]);   // parts
    color("#222", 0.8) translate([x_in + 1, y_b - t/2 - 2.5, z_s - 5.1]) cube([5.1, 2.5, 10.2]); // header
    color("#555", 0.6) translate([x_in + 1, y_b - t/2 - 2.5 - dupont_len, z_s - 5.1]) cube([5.1, dupont_len, 10.2]);
    color("gold", 0.9) translate([x_edge, y_s - fl/2, z_s - fl/2]) cube([rf_flange[1], fl, fl]);
    color("gold", 0.9) translate([x_edge + rf_flange[1], y_s, z_s]) rotate([0,90,0]) cylinder(d=6.35, h=rf_sma_len - rf_flange[1]);
    if (with_antenna)
        color("#111", 0.6) translate([x_edge + rf_sma_len - 4, y_s, z_s]) rotate([0,90,0]) cylinder(d=antenna[1], h=antenna[0]);
}

// ======================= OUTPUT =======================
module fix() { if (mirror_fix) mirror([1,0,0]) children(); else children(); }
if (part == "case") {
    fix() base_case();
    if (show_module && $preview) fix() translate([0,0,z_base_bot]) module_ghost();
} else if (part == "stand") {
    fix() translate([0,0,-base_t]) shell();      // printed open side down
} else if (part == "base") {
    fix() base_plate();
} else if (part == "assembly") {
    fix() {
        color("#3b6ea5") shell();
        color("#6b8fc5") base_plate();
        if (show_module) {
            incline() translate([0,0,-pocket_depth]) module_ghost();
            if (radio) rf_ghost();
        }
    }
}
