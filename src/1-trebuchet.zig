const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;
const Writer = std.io.Writer;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./files/trebuchet", .{});
    defer file.close();

    var buffer: [1000000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();
    var number_str = std.ArrayList(u8).init(allocator);
    defer number_str.deinit();
    var number = std.ArrayList(i32).init(allocator);
    defer number.deinit();

    while (true) {
        file.reader().streamUntilDelimiter(line.writer(), '\n', null) catch {
            break;
        };
        var first: ?u8 = null;
        var last: ?u8 = null;
        for (line.items) |c| {
            if (std.ascii.isDigit(c)) {
                if (first) |_| {
                    last = c;
                } else {
                    first = c;
                }
            }
        }
        const fd: u8 = first.?;
        const ld: u8 = last orelse fd;
        try number_str.append(fd);
        try number_str.append(ld);
        try number.append(try std.fmt.parseInt(i32, number_str.items, 0));
        line.clearRetainingCapacity();
        number_str.clearRetainingCapacity();
    }

    var total: i32 = 0;
    for (number.items) |n| {
        total += n;
    }
    print("Total: {any}\n", .{total});
}
