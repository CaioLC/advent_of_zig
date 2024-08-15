const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

pub fn main() !void {
    // file pointer
    const file = try std.fs.cwd().openFile("./files/2-cube", .{});

    // memory allocator
    var buffer: [100_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // lists
    var line = ArrayList(u8).init(allocator);
    defer line.deinit();

    var color_parser = ArrayList(u8).init(allocator);
    defer color_parser.deinit();

    var res = ArrayList(i32).init(allocator);
    defer res.deinit();

    outer: while (true) {
        file.reader().streamUntilDelimiter(line.writer(), '\n', null) catch |e| {
            print("{}\n", .{e});
            break;
        };
        var red: i32 = 0;
        var green: i32 = 0;
        var blue: i32 = 0;
        defer line.clearRetainingCapacity();

        if (line.items.len == 0) break;

        // separate Game | Rounds
        var game_rounds = std.mem.tokenizeAny(u8, line.items, ":");
        const game = game_rounds.next().?;
        const rounds = game_rounds.next().?;

        var game_n = std.mem.tokenizeAny(u8, game, " ");
        _ = game_n.next().?;
        _ = try std.fmt.parseInt(i32, game_n.next().?, 0);

        var round = std.mem.tokenizeAny(u8, rounds, ";");
        // for each round
        while (round.next()) |r| {
            min_cubes(r, &red, &green, &blue) catch |e| {
                print("{}", .{e});
                break :outer;
            };
        }
        try res.append(red * green * blue);
    }
    var total: i32 = 0;
    for (res.items) |r| total += r;
    print("total: {}\n", .{total});
}

// fn implausible(round: []const u8, array: *ArrayList) bool {
fn min_cubes(round: []const u8, red: *i32, green: *i32, blue: *i32) !void {
    var pick = std.mem.tokenizeAny(u8, round, ",");
    while (pick.next()) |p| {
        var n_color = std.mem.tokenizeAny(u8, p, " ");
        const n = try std.fmt.parseInt(i32, n_color.next().?, 0);
        const color = n_color.next().?;
        var match = false;
        if (std.mem.eql(u8, color, "red")) {
            match = true;
            if (n > red.*) red.* = n;
        }
        if (std.mem.eql(u8, color, "green")) {
            match = true;
            if (n > green.*) green.* = n;
        }
        if (std.mem.eql(u8, color, "blue")) {
            match = true;
            if (n > blue.*) blue.* = n;
        }
        if (!match) return error.ColorNotFound;
    }
}
