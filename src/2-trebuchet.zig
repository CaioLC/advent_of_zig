const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

pub fn main() !void {
    // load file handle
    const file = try std.fs.cwd().openFile("./files/trebuchet", .{});

    // lists
    var buffer: [1_000_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var text_list = ArrayList(u8).init(allocator);
    defer text_list.deinit();

    var number_str = ArrayList(u8).init(allocator);
    defer number_str.deinit();

    var number = ArrayList(i32).init(allocator);
    defer number.deinit();

    // program
    while (true) {
        file.reader().streamUntilDelimiter(text_list.writer(), '\n', null) catch {
            // print("{}\n", .{e});
            break;
        };

        var fd: ?u8 = null;
        var ld: ?u8 = null;
        for (text_list.items, 0..text_list.items.len) |c, i| {
            if (std.ascii.isDigit(c)) {
                register_digit(c, &fd, &ld);
            } else {
                const num_str: ?u8 = parse_str(text_list.items[i..text_list.items.len]);
                if (num_str) |n| {
                    register_digit(n, &fd, &ld);
                }
            }
        }
        try number_str.append(fd.?);
        try number_str.append(ld orelse fd.?);
        // print("text: {s} | digits: {s}\n", .{ text_list.items, number_str.items });
        try number.append(try std.fmt.parseInt(i32, number_str.items, 0));
        text_list.clearRetainingCapacity();
        number_str.clearRetainingCapacity();
    }
    var total: i32 = 0;
    for (number.items) |n| total += n;
    print("Total: {any}", .{total});
}

fn parse_str(text_str: []u8) ?u8 {
    if (text_str.len < 3) return null;
    if (std.mem.eql(u8, text_str[0..3], "one")) return "1".*[0];
    if (std.mem.eql(u8, text_str[0..3], "two")) return "2".*[0];
    if (std.mem.eql(u8, text_str[0..3], "six")) return "6".*[0];

    if (text_str.len < 4) return null;
    if (std.mem.eql(u8, text_str[0..4], "four")) return "4".*[0];
    if (std.mem.eql(u8, text_str[0..4], "five")) return "5".*[0];
    if (std.mem.eql(u8, text_str[0..4], "nine")) return "9".*[0];
    if (std.mem.eql(u8, text_str[0..4], "zero")) return "0".*[0];

    if (text_str.len < 5) return null;
    if (std.mem.eql(u8, text_str[0..5], "three")) return "3".*[0];
    if (std.mem.eql(u8, text_str[0..5], "seven")) return "7".*[0];
    if (std.mem.eql(u8, text_str[0..5], "eight")) return "8".*[0];
    return null;
}

fn register_digit(digit: u8, fd: *?u8, ld: *?u8) void {
    if (ld.*) |*d| d.* = digit else {
        if (fd.*) |_| ld.* = digit else fd.* = digit;
    }
}
