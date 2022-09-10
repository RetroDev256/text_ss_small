const std = @import("std");
const linux = std.os.linux;

// Configuration:
const term_x: u32 = 80; // Columns on the terminal
const term_y: u32 = 25; // Rows on the terminal
const banner = "Retro";
const wait_time = linux.timespec{ // Time to pause for each frame
    .tv_sec = 0,
    .tv_nsec = 150000000,
};

pub export fn _start() void {
    while (true) { // render & update placement
        update_loc();
        place_banner();
        _ = linux.nanosleep(&wait_time, null);
    }
}

// banner placing coordinates
const place_x: u32 = term_x - banner.len;
const place_y: u32 = term_y - 1;

// initial location and velocity direction of the banner
var loc_x: u32 = place_x / 2;
var loc_y: u32 = place_y / 2;
var vel_x: bool = undefined;
var vel_y: bool = undefined;
fn update_loc() void {
    // if a wall *has* been hit, flip the velocities
    if (loc_y == place_y) vel_y = false;
    if (loc_x == place_x) vel_x = false;
    // shift the position of the banner
    loc_y = if (vel_y) loc_y + 1 else loc_y - 1;
    loc_x = if (vel_x) loc_x + 1 else loc_x - 1;
    // if a base wall *will* be hit, flip the velocities
    if (loc_y == 0) vel_y = true;
    if (loc_x == 0) vel_x = true;
}

fn place_banner() void {
    // ANSI terminal code, goto top left.
    _ = linux.write(1, "\x1B[1;1H", 6);
    // loop through the rows on the terminal
    var y: u32 = 0;
    while (y < term_y) : (y += 1) {
        // stack allocate buffer to hold the line
        var renderline: [term_x + 1]u8 = undefined;
        for (renderline) |*space| {
            space.* = ' ';
        }
        renderline[term_x] = '\n';
        if (y == loc_y) {
            const dest_ptr = @ptrCast([*]u8, renderline[loc_x..]);
            @memcpy(dest_ptr, banner, banner.len);
        }
        // write the row to the terminal
        _ = linux.write(1, &renderline, term_x + 1);
    }
}
