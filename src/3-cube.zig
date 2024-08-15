const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

const RED: i32 = 12;
const GREEN: i32 = 13;
const BLUE: i32 = 14;

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
        defer line.clearRetainingCapacity();

        if (line.items.len == 0) break;

        // separate Game | Rounds
        var game_rounds = std.mem.tokenizeAny(u8, line.items, ":");
        const game = game_rounds.next().?;
        const rounds = game_rounds.next().?;

        var game_n = std.mem.tokenizeAny(u8, game, " ");
        _ = game_n.next().?;
        const n = try std.fmt.parseInt(i32, game_n.next().?, 0);
        // print("{} | {s}\n", .{ n, rounds });

        // examine each round if plausible
        // if round is inplausible then we can safely move to next game
        var round = std.mem.tokenizeAny(u8, rounds, ";");
        while (round.next()) |r| {
            if (implausible(r) catch |e| {
                print("{}", .{e});
                break :outer;
            }) {
                // print("Implausible: {s}\n", .{r});
                continue :outer;
            }
        }

        try res.append(n);
    }
    var total: i32 = 0;
    for (res.items) |r| total += r;
    print("total: {}\n", .{total});
}

// fn implausible(round: []const u8, array: *ArrayList) bool {
fn implausible(round: []const u8) !bool {
    var pick = std.mem.tokenizeAny(u8, round, ",");
    while (pick.next()) |p| {
        var n_color = std.mem.tokenizeAny(u8, p, " ");
        const n = try std.fmt.parseInt(i32, n_color.next().?, 0);
        const color = n_color.next().?;
        const imp = implausible_color(color, n) catch |e| {
            print("{}: {s}\n", .{ e, color });
            return e;
        };
        if (imp) return imp;
    }
    return false;
}

fn implausible_color(color: []const u8, n: i32) !bool {
    var match = false;
    if (std.mem.eql(u8, color, "red")) {
        match = true;
        if (n > RED) return true;
    }
    if (std.mem.eql(u8, color, "green")) {
        match = true;
        if (n > GREEN) return true;
    }
    if (std.mem.eql(u8, color, "blue")) {
        match = true;
        if (n > BLUE) return true;
    }
    if (!match) return error.ColorNotFound;
    return false;
}
