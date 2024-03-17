//! This mod replaces the X-axis v slot wheels with an MGN9 linear rail.
//!
//! If you don't know if you need linear rails on the X-axis then you probably won't benefit from this. But if you
//! _want_ linear rails like I did, then enjoy.
//!
//! - **Dimensional accuracy and flow calibration is required in order for the nut trap to fit the nuts securely**.
//! - [BOM](bom/bom.csv).
//!   - Either an MGN9C or MGN9H carriage can be used. Ideally use rails with some preload to improve wobble along the Y
//!   axis.
//! - Use [Voron print settings](https://docs.vorondesign.com/sourcing.html#print-settings).
//!   - Probably avoid PLA due to the nut trap only being two walls thick.
//! - No additional supports required.
//! - Print STLs in their default orientation.
//!
//! After installation remember to re-calibrate the Z-offset and recreate the bed mesh.
//!
//! Measurements and spacers inspired by https://www.printables.com/model/716958-linear-x-rail-mod-ender-3-v3-se. This
//! version doesn't sacrifice X-axis movement and doesn't need a new endstop. The nozzle sits a bit forward in the Y
//! axis.
//!
//! See [results.md](results.md) for input shaper results.
//!
//! Ender 3 V3 SE reference model taken from
//! https://www.printables.com/model/672045-ender-3-v3-se-reference-models-step-files.
//!
//! # Development
//!
//! Prerequisites:
//!
//! - https://github.com/nophead/NopSCADlib/tree/master
//! - https://github.com/revarbat/BOSL
//!
//! PYTHONPATH is required to generate the BOM with costs:
//!
//! ```bash
//! PYTHONPATH=$PWD ~/.local/share/OpenSCAD/libraries/NopSCADlib/scripts/make_all.py
//! ```
//!
//! ![assets/irl.jpg](assets/irl.jpg)
include <BOSL/shapes.scad>;
include <NopSCADlib/lib.scad>;
include <v-slot-customizer-and-openscad-library/v-slot_lib.scad>;

show_rail = true;

show_toolhead = true;

mount_thickness = 7;
mount_extra_width = 1;

bracket_mount_screw_x = 31;

metal_braket_space = 4;

bracket_extra_width = 21;

carriage_type = "MGN9C"; // [MGN9H, MGN9C]

mount_type = "Hex nut"; // [Hex nut, Square nut, Threaded insert]

// Select the component to export to STL.
print_component = "None"; //[Carriage, Spacers]

tolerance = 0.1;

mounting_carriage = carriage_type == "MGN9C" ? MGN9C_carriage : MGN9H_carriage;

rail_offset = 2.8 - 0.4; // The mounting blocks of the original model.

print_orientation = print_component != "None";

_show_rail = print_component != "None" ? false : show_rail;

rail_pos = 60;

$fn = 60;

M5x4 = [ "M5x4", 4, 10, 8.5, 5, 7.5, 0.5, 7.5, 7.5, 3.5, 0.8 ];
block_width = 15;
middle_block_width = rail_pitch(MGN9) * 3 - 1;

block_depth = 0.6;

end_block_width = rail_pitch(MGN9) * 2 - 1;

module toolhead()
{
    not_on_bom()
    {
        if (_show_rail)
        {
            if (show_toolhead)
            {
                // Offset is eyeballed.
                color([ 0.3, 0.3, 0.3 ]) translate([ -1.45 + rail_pos, 16, 19 + 3.5 - rail_offset ])
                    rotate([ 0, 0, 180 ]) import("../ender-3-v3-se-reference-models-step-files/full-toolhead.stl");
            }
        }
    }
}

module toolhead_frame()
{
    not_on_bom()
    {
        if (_show_rail)
        {
            if (show_toolhead)
            {
                color([ 0.3, 0.3, 0.3 ]) translate([ 30 + rail_pos, 14.8, 19.1 + 3.5 - rail_offset ])
                    rotate([ 0, 0, 180 ]) import("../ender-3-v3-se-reference-models-step-files/frame.stl");
            }
        }
    }
}

//! Attach the spacers to the assembly, taking note that the left spacer is offset by one screw hole.
//!
//! Remember to clean and lubricate both the carriage and rail.
module linear_rail_assembly()
{
    pose(a = [ 55, 0, 205 ]) assembly("linear_rail")
    {
        if (_show_rail)
        {
            explode(10) rail_assembly(mounting_carriage, 300, rail_pos, carriage_end_colour = "green",
                                      carriage_wiper_colour = "red");
        }
        rotation = print_component == "Spacers" ? 180 : 0;
        distance = print_component == "Spacers" ? rail_pitch(MGN9) * 3 : rail_pitch(MGN9) * 7 - rail_pitch(MGN9) / 2;
        rotate([ rotation, 0, 0 ])
        {
            middle_spacer_assembly();
            translate([ -distance, 0, 0 ]) right_spacer_assembly();
            translate([ distance - rail_pitch(MGN9), 0, 0 ]) left_spacer_assembly();
        }
        explode(-10) not_on_bom()
        {
            if (_show_rail)
            {
                color("silver") translate([ -150, 0, -extrusion_height(E2020) / 2 - rail_offset ]) rotate([ 0, 90, 0 ])
                    V_slot("20x20", 290);
            }
        }
    }
}

//! Attach the carriage to the rail. Note that the front two screws won't be easily accessible once the PCB is mounted.
module carriage_rail_assembly()
{
    pose(a = [ 55, 0, 205 ]) assembly("carriage_rail")
    {
        linear_rail_assembly();
        carriage_assembly();
        carriage_screws();
    }
}

//! Screw the frame into the carriage, ensuring that the frame is flush on the carriage. Remember to insert the belts
//! before re-assembling the everything else.
module toolhead_carriage_assembly()
{
    pose(a = [ 55, 0, 205 ]) assembly("toolhead_carriage")
    {
        carriage_rail_assembly();
        explode([ 0, 20, 0 ]) toolhead_frame();
        explode([ 0, 40, 0 ]) frame_screws();

        translate([ 0, 0, -extrusion_height(E2020) / 2 - rail_offset ])
        {
            if (_show_rail)
            {
                not_on_bom()
                {
                    belt(GT2x6, [
                        [ 170, 0, -extrusion_height(E2020) / 2 + 1 ], [ -170, 0, -extrusion_height(E2020) / 2 + 1 ]
                    ]);
                }
            }
        }
    }
}

module middle_spacer_stl()
{
    stl("middle_spacer")
    {
        rotate([ 0, 90, 0 ]) difference()
        {
            translate([ -middle_block_width / 2, -block_width / 2, -rail_offset - block_depth ])
                cube([ middle_block_width, block_width, rail_offset + block_depth + 1.6 ]);
            translate([ -150, 0, -extrusion_height(E2020) / 2 - rail_offset + tolerance ]) rotate([ 0, 90, 0 ])
                V_slot("20x20", 300);
            translate([ 0, -tolerance, 0 ]) hull() rail(MGN9, 300);
            translate([ 0, tolerance, 0 ]) hull() rail(MGN9, 300);

            translate([ 0, 0, -rail_offset * 2 ])
                rail_hole_positions(MGN9, middle_block_width, first = 0, screws = 3, both_ends = true)
            {
                cylinder(h = 20, r = screw_radius(M3_cap_screw) + tolerance);
            }
        }
    }
}

// Trim for the left side where the x motor mount overlaps with the extrusion.
module two_hole_spacer(is_left)
{

    difference()
    {
        // 1 mm between the rail and x-motor
        trimmed_width = block_width / 2 - (block_width - rail_width(MGN9) - 2) / 2;
        trim_distance = block_width / 2 - trimmed_width;
        union()
        {

            translate([ -end_block_width / 2, -block_width / 2 + trim_distance, -rail_offset - block_depth ])
                cube([ end_block_width, block_width - trim_distance, rail_offset + block_depth + 1.6 ]);
            if (is_left == false)
            {
                translate([ 12 - end_block_width / 2, -block_width / 2, -rail_offset - block_depth ])
                    cube([ end_block_width - 12, block_width, rail_offset + block_depth + 1.6 ]);
            }
        }
        // translate([ 0, 0, -extrusion_height(E2020) / 2 - rail_offset ]) rotate([ 0, 90, 0 ]) extrusion(E2020, 300);
        translate([ -150, 0, -extrusion_height(E2020) / 2 - rail_offset + tolerance ]) rotate([ 0, 90, 0 ])
            V_slot("20x20", 300);

        translate([ 0, -tolerance, 0 ]) hull() rail(MGN9, 300);
        translate([ 0, tolerance, 0 ]) hull() rail(MGN9, 300);

        translate([ 0, 0, -rail_offset * 2 ])
            rail_hole_positions(MGN9, end_block_width, first = 0, screws = 2, both_ends = true)
        {
            cylinder(h = 20, r = screw_radius(M3_cap_screw) + tolerance);
        }

        label = is_left ? "L" : "R";
        rotate([ 0, 0, 180 ]) translate([ -4, -4, -0.4 ]) linear_extrude(1) text(label, size = 8);
    }
}

module middle_spacer_screws()
{
    if (show_rail)
    {
        rail_screws(MGN9, middle_block_width, 6, screws = 3, index_screws = 0);
        rail_hole_positions(MGN9, middle_block_width, screws = 3)
        {
            translate([ 0, 0, -rail_offset - carriage_clearance(E2020) + t_nut_tab(M3_hammer_nut)[1] - 0.1 ])
                rotate([ 180, 0, 0 ]) sliding_t_nut(M3_hammer_nut);
        }
    }
}

module end_spacer_screws()
{
    if (show_rail)
    {
        rail_screws(MGN9, end_block_width, 6, screws = 2, index_screws = 0);
        rail_hole_positions(MGN9, end_block_width, screws = 2)
            translate([ 0, 0, -rail_offset - carriage_clearance(E2020) + t_nut_tab(M3_hammer_nut)[1] - 0.1 ])
                rotate([ 180, 0, 0 ]) sliding_t_nut(M3_hammer_nut);
    }
}

module left_spacer_stl()
{
    stl("left_spacer") rotate([ 0, 90, 0 ]) two_hole_spacer(is_left = true);
}

module right_spacer_stl()
{
    stl("right_spacer") rotate([ 0, 90, 0 ]) two_hole_spacer(is_left = false);
}

module left_spacer_assembly()
{
    explode(6) rotate([ 0, $preview ? -90 : 0 ]) left_spacer_stl();
    end_spacer_screws();
}

module right_spacer_assembly()
{
    explode(6) rotate([ 0, $preview ? -90 : 0 ]) right_spacer_stl();
    end_spacer_screws();
}

module middle_spacer_assembly()
{
    explode(6) rotate([ 0, $preview ? -90 : 0 ]) middle_spacer_stl();
    middle_spacer_screws();
}

M5_flat_screw = [
    "M5_wafer", "M5 wafer head", hs_cap, 5, 9.5, 1.5, 1.4, 3.0, 22, M5_washer, M5_nut, M5_tap_radius,
    M5_clearance_radius
];

module frame_screws()
{
    if (show_rail)
    {
        rotate([ 0, print_orientation ? 90 : 0, 0 ]) translate([ rail_pos, 0, carriage_height(mounting_carriage) ])
            translate([ 0, 14.9 + 2, 2.5 - rail_offset ])
        {
            translate([ bracket_mount_screw_x / 2, 0, 0 ]) rotate([ -90, 0, 0 ]) screw(M5_flat_screw, 6);
            translate([ -bracket_mount_screw_x / 2, 0, 0 ]) rotate([ -90, 0, 0 ]) screw(M5_flat_screw, 6);
        }
    }
}

module m5_screw_holes()
{
    translate([ 0, 14.9, 2.5 - rail_offset ])
    {
        translate([ bracket_mount_screw_x / 2, 0, 0 ]) rotate([ 0, -90, 0 ])
            teardrop(2.5, h = metal_braket_space, cap_h = 2.6);
        translate([ -bracket_mount_screw_x / 2, 0, 0 ]) rotate([ 0, -90, 0 ])
            teardrop(2.5, h = metal_braket_space, cap_h = 2.6);
    }
}

module carriage_nut_trap()
{
    n = mount_type == "Hex nut" ? M5_nut : M5nS_thin_nut;
    translate([ 0, 10, 2.5 - rail_offset ])
    {
        translate([ bracket_mount_screw_x / 2, -0.2, 0 ]) rotate([ 90, 0, 0 ])
            nut_trap(M5_cap_screw, n, depth = 0, h = 8.0);

        translate([ -bracket_mount_screw_x / 2, -0.2, 0 ]) rotate([ 90, 0, 0 ])
            nut_trap(M5_cap_screw, n, depth = 0, h = 8.0);
    }
}

module carriage_nuts()
{
    if (show_rail)
    {
        n = mount_type == "Hex nut" ? M5_nut : M5nS_thin_nut;
        rotate([ 0, print_orientation ? 90 : 0, 0 ]) translate([ rail_pos, 0, carriage_height(mounting_carriage) ])
            translate([ 0, 13.6, 2.5 - rail_offset ])
        {
            translate([ bracket_mount_screw_x / 2, -0.2, 0 ]) rotate([ 90, 0, 0 ]) nut(M5_nut);

            translate([ -bracket_mount_screw_x / 2, -0.2, 0 ]) rotate([ 90, 0, 0 ]) nut(M5_nut);
        }
    }
}

module threaded_insert_trap()
{
    translate([ 0, 13, -1 ])
    {
        translate([ bracket_mount_screw_x / 2, 0, 0 ]) rotate([ 90, 0, 0 ])
            insert_hole(CNCKM5, counterbore = 0, horizontal = false);
        translate([ -bracket_mount_screw_x / 2, 0, 0 ]) rotate([ 90, 0, 0 ])
            insert_hole(CNCKM5, counterbore = 0, horizontal = false);
    }
}

module carriage_screws()
{
    translate([ rail_pos, 0, carriage_height(mounting_carriage) ]) difference()
    {
        if (_show_rail)
        {
            translate([ 0, 0, -carriage_height(mounting_carriage) + mount_thickness - 3 ])
                carriage_hole_positions(mounting_carriage)
            {
                color("silver") screw_and_washer(M3_cap_screw, 8);
            };
        }
    }
}

module support()
{
    translate([ -20.1, 0.10, 0.8 ])
    {
        difference()
        {
            union()
            {
                translate([ 0, 10, -10.5 + 1 ]) rotate([ 90, 180, 90 ]) right_triangle([ 5, 0.8, 5 ]);

                translate([ 2, 10.4, -10.5 + 1 ]) rotate([ 90, 180, 90 ]) cube([ 0.4, 0.8, 0.2 ]);

                translate([ 4.2, 10.4, -10.5 + 1 ]) rotate([ 90, 180, 90 ]) cube([ 1.2, 0.8, 0.4 ]);
                translate([ 4.2, 10, -10.5 + 1 ]) rotate([ 90, 180, 90 ]) cube([ 0.8, 0.8, 0.4 ]);

                translate([ -0.4, 10, -10.5 + 1 ]) rotate([ 90, 180, 90 ]) cube([ 0.4, 0.8, 0.4 ]);

                translate([ -0.4, 5.3, -10.5 + 1 ]) rotate([ 90, 180, 90 ]) cube([ 0.4, 0.8, 0.6 ]);
            }
            translate([ 4.6, 10.4, -10.5 + 1.05 ]) rotate([ 90, 180, 90 ]) cube([ 0.9, 0.9, 0.4 ]);
        }
    }
}

module toolhead_carriage_MGN9C_stl()
{
    stl("toolhead_carriage_MGN9C") toolhead_carriage_base(MGN9C_carriage);
}

module toolhead_carriage_MGN9H_stl()
{
    stl("toolhead_carriage_MGN9H") toolhead_carriage_base(MGN9H_carriage);
}

module toolhead_carriage_base(mounting_carriage)
{
    rotate([ 0, 90, 0 ]) translate([ rail_pos, 0, carriage_height(mounting_carriage) ]) difference()
    {
        union()
        {
            // mount
            difference()
            {
                translate([
                    -carriage_length(MGN9C_carriage) / 2 - bracket_extra_width / 2,
                    -mount_extra_width / 2 - carriage_width(mounting_carriage) / 2 - metal_braket_space + 1, 0
                ])
                {
                    cube([
                        carriage_length(MGN9C_carriage) + bracket_extra_width,
                        carriage_width(mounting_carriage) + mount_extra_width + metal_braket_space,
                        mount_thickness
                    ]);
                }
                translate([ 0, 0, -carriage_height(mounting_carriage) - 0.1 ])
                    carriage_hole_positions(mounting_carriage)
                {
                    cylinder(h = 10, r = 1.5 + tolerance);
                };
            }

            color("blue")
            {
                translate([ 0, 0, 1.4 ]) support();
                translate([ 0, 0, 4.6 ]) support();
            }

            // bracket
            bracket_height = 16.5 + 1 - 1.4;

            translate([
                -carriage_length(MGN9C_carriage) / 2 - bracket_extra_width / 2,
                mount_extra_width / 2 + carriage_width(mounting_carriage) / 2 - 0.2,
                -(bracket_height - mount_thickness) + 1
            ])
            {
                cube([
                    carriage_length(MGN9C_carriage) + bracket_extra_width,
                    metal_braket_space - mount_extra_width / 2 + 0.8,
                    bracket_height
                ]);
            }

            rotate([ -90, 90, 180 ])
                translate([ 0, (carriage_length(MGN9C_carriage) + bracket_extra_width) / 2 - 5, -10.5 + 1 ])
                    right_triangle([ 7.6, 5, 9.8 ]);
            rotate([ -90, 90, 180 ])
                translate([ 0, -((carriage_length(MGN9C_carriage) + bracket_extra_width) / 2), -10.5 + 1 ])
                    right_triangle([ 7.6, 5, 9.8 ]);

            translate([
                (carriage_length(MGN9C_carriage) + bracket_extra_width) / 2 - 5, 5,
                -(bracket_height - mount_thickness) + 1
            ]) cube([ 5, 6, bracket_height - 1 ]);
            translate([
                -(carriage_length(MGN9C_carriage) + bracket_extra_width) / 2, 5, -(bracket_height - mount_thickness) + 1
            ]) cube([ 5, 6, bracket_height - 1 ]);
        }

        m5_screw_holes();
        if (mount_type == "Hex nut" || mount_type == "Square nut")
        {
            carriage_nut_trap();
        }
        if (mount_type == "Threaded insert")
        {
            threaded_insert_trap();
        }

        translate([ 0, 0, -6 ]) carriage_hole_positions(mounting_carriage)
        {
            cylinder(h = 10, r = washer_radius(M3_washer) + 0.3);
        };
    }

    if (_show_rail && mount_type == "Threaded insert")
    {
        translate([ 0, 14.6, carriage_height(mounting_carriage) - 1 ])
        {
            translate([ bracket_mount_screw_x / 2, 0, 0 ]) rotate([ -90, 0, 0 ]) insert(CNCKM5);
            translate([ -bracket_mount_screw_x / 2, 0, 0 ]) rotate([ -90, 0, 0 ]) insert(CNCKM5);
        }
    }
}

//! First remove the two supports at the top of the model.
//!
//! ![carriage-supports.png](assets/carriage-supports.png)
//!
//! The nuts should be a tight fit. If you have trouble pushing the nut in, check if there is any substantial corner
//! blobbing due to lack of pressure advance and/or insert an M5 screw from the otherside and tighten.
module carriage_assembly()
{
    pose(a = [ 55, 180, 75 ]) assembly("carriage")
    {
        rot = $preview ? -90 : 0;
        rotate([ 0, rot, 0 ]) toolhead_carriage_MGN9C_stl();

        explode([ 0, -10, -5 ]) carriage_nuts();
        hidden()
        {
            rotate([ 0, rot, 0 ]) toolhead_carriage_MGN9H_stl();
        }
    }
}

module main_assembly()
{
    assembly("main")
    {
        toolhead_carriage_assembly();
    }
}

if ($preview)
{
    main_assembly();
}