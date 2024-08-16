const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

const LINE_LEN = 140;

const Pointer = struct {
    start: u8,
    end: u8,
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./files/3-gears-mini", .{});
    defer file.close();

    var buf: [3 * LINE_LEN]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);

    var array_buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&array_buf);
    const allocator = fba.allocator();

    var symbols = ArrayList(u8).init(allocator);
    defer symbols.deinit();

    var gears = ArrayList(u8).init(allocator);
    defer gears.deinit();

    var number_slices = ArrayList(Pointer).init(allocator);
    defer number_slices.deinit();

    var number = ArrayList(u16).init(allocator);
    defer number.deinit();

    var row: usize = 0;
    while (true) {
        file.reader().streamUntilDelimiter(fbs.writer(), '\n', null) catch |e| {
            print("{}\n", .{e});
            break;
        };
        print("{s}\n", .{buf});
        row += 1;
        if (row % 3 == 0) {
            const l1 = buf[LINE_LEN * 0 .. LINE_LEN * 1];
            const l2 = buf[LINE_LEN * 1 .. LINE_LEN * 2];
            const l3 = buf[LINE_LEN * 2 .. LINE_LEN * 3];

            // whenever we get here, we have 3 full buffers;
            // check l1 symbols
            try parse_line(l1, &symbols, &number_slices);
            print("l1: {any} | numbers: {any}\n", .{ symbols.items, number_slices.items });
            // inline_neighbors(symbols, l1);
            // forward_neighbors(s_buf, l1, l2);
            symbols.clearRetainingCapacity();

            // check b2-> b1 | b3
            try parse_line(l2, &symbols, &number_slices);
            print("l2: {any}\n", .{symbols.items});
            // backward_neighbors(s_buf, l2, l1);
            // inline_neighbors(s_buf, l2);
            // forward_neighbors(s_buf, l2, l3);
            symbols.clearRetainingCapacity();

            // check b3-> b2
            try parse_line(l3, &symbols, &number_slices);
            print("l3: {any}\n", .{symbols.items});
            // backward_neighbors(s_buf, l3, l2);
            symbols.clearRetainingCapacity();
            fbs.reset();
            break;
        }
    }
}

fn parse_line(line: []u8, sym: *ArrayList(u8), num: *ArrayList(Pointer)) !void {
    var start: ?usize = null;
    var end: ?usize = null;
    for (line, 0..LINE_LEN) |c, index| {
        if (c == '.') {
            if (start) |s| {
                if (end) |e| {
                    try num.append(Pointer{ .start = @intCast(s), .end = @intCast(e) });
                } else return error.SliceMalFormed;
                start = null;
                end = null;
            }
            continue;
        }
        if (std.ascii.isDigit(c)) {
            if (start) |_| {
                end = index + 1;
            } else {
                start = index;
                end = index + 1;
            }
            continue;
        }
        try sym.append(@intCast(index));
    }
}
