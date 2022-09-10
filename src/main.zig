const std = @import("std");
const linux = std.os.linux;

// Configuration:
const term_x: u32 = 80; // Columns on the terminal
const term_y: u32 = 25; // Rows on the terminal
const banner = [_][]const u8{ // Message
    "    ____       __",
    "   / __ \\___  / /__________",
    "  / /_/ / _ \\/ __/ ___/ __ \\",
    " / _, _/  __/ /_/ /  / /_/ /",
    "/_/ |_|\\___/\\__/_/   \\____/",
};
const time = .{ // Frame time
    .tv_sec = 0,
    .tv_nsec = 150000000,
};

pub export fn _start() void {
    while (true) { // render & update placement
        update_loc();
        place_banner();
        _ = linux.nanosleep(&time, null);
    }
}

// dimensions of the banner, and placable coordinates
const banner_x: u32 = str_arr_width(&banner);
const banner_y: u32 = banner.len;
const place_x: u32 = term_x - banner_x;
const place_y: u32 = term_y - banner_y;

// location and velocity direction of the banner
var loc_x: u32 = place_x / 2;
var loc_y: u32 = place_y / 2;
var vel_x: bool = true;
var vel_y: bool = true;
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
s
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
        // If the row contains the banner, copy banner to the row
        const ban_line = y -% loc_y;
        if (ban_line < banner_y) {
            const dest_ptr = @ptrCast([*]u8, renderline[loc_x..]);
            const src_ptr = @ptrCast([*]const u8, banner[ban_line]);
            const line_len = banner[ban_line].len;
            @memcpy(dest_ptr, src_ptr, line_len);
        }
        // write the row to the terminal
        _ = linux.write(1, &renderline, term_x + 1);
    }
}

// compile time function for finding the width of the symbol
fn str_arr_width(in: []const []const u8) u32 {
    var len: u32 = 0;
    for (in) |line| {
        if (line.len > len) {
            len = line.len;
        }
    }
    return len;
}
