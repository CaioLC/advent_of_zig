const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

const LINE_LEN = 140;
// const LINE_LEN = 10;

const Pointer = struct {
    number: usize,
    start: usize,
    end: usize,
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./files/3-gears", .{});
    defer file.close();

    var buf: [LINE_LEN]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);

    var array_buf: [3000000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&array_buf);
    const allocator = fba.allocator();

    var symbols = ArrayList(usize).init(allocator);
    defer symbols.deinit();

    var number_slices = ArrayList(Pointer).init(allocator);
    defer number_slices.deinit();

    var number = ArrayList(usize).init(allocator);
    defer number.deinit();

    var row: usize = 0;
    while (true) {
        file.reader().streamUntilDelimiter(fbs.writer(), '\n', null) catch |e| {
            print("{}\n", .{e});
            break;
        };
        // print("{s}\n", .{buf});
        try parse_line(&buf, row, &symbols, &number_slices);
        fbs.reset();
        row += 1;
    }
    // print("numbers: {any}\n", .{number_slices.items});
    // print("symbols: {any}\n", .{symbols.items});
    try neighbors(&number_slices, &symbols, &number);
    print("gears: {any}\n", .{number.items});
    var total: usize = 0;
    for (number.items) |n| total += n;
    print("total: {any}\n", .{total});
}

/// Builds a list of symbols and numbers for the buffer
fn parse_line(line: []u8, row: usize, sym: *ArrayList(usize), num: *ArrayList(Pointer)) !void {
    var start: ?usize = null;
    var end: ?usize = null;
    for (line, 0..LINE_LEN) |c, index| {
        if (c == '.') {
            if (start) |s| {
                if (end) |e| {
                    // print("numb: {s}\n", .{line[s..e]});
                    const numb = try std.fmt.parseUnsigned(usize, line[s..e], 0);
                    try num.append(Pointer{
                        .number = numb,
                        .start = s + row * LINE_LEN,
                        .end = e + row * LINE_LEN,
                    });
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
        // if not '.' nor number, then it is a symbol
        try sym.append(index + row * LINE_LEN);
        // is symbol comes right after a numer, we also need to register the number
        if (start) |s| {
            if (end) |e| {
                // print("numb: {s}\n", .{line[s..e]});
                const numb = try std.fmt.parseUnsigned(usize, line[s..e], 0);
                try num.append(Pointer{
                    .number = numb,
                    .start = s + row * LINE_LEN,
                    .end = e + row * LINE_LEN,
                });
            } else return error.SliceMalFormed;
            start = null;
            end = null;
        }
    }
}

fn neighbors(num: *ArrayList(Pointer), sym: *ArrayList(usize), res: *ArrayList(usize)) !void {
    num_loop: for (num.items) |n| {
        //inline: symbol can be left or right
        const left = @subWithOverflow(n.start, 1)[0];
        const right = n.end;
        for (sym.items) |s| {
            if (s == left or s == right) {
                try res.append(n.number);
                continue :num_loop;
            }
            // if (s > right) break;
        }

        // if not inline, we check above or below:
        for (n.start..n.end) |p| {
            for (sym.items) |s| {
                if (s == @subWithOverflow(p, LINE_LEN - 1)[0] or
                    s == @subWithOverflow(p, LINE_LEN)[0] or
                    s == @subWithOverflow(p, LINE_LEN + 1)[0] or
                    s == p + LINE_LEN - 1 or
                    s == p + LINE_LEN or
                    s == p + LINE_LEN + 1)
                {
                    try res.append(n.number);
                    continue :num_loop;
                }
                // if (s > p + LINE_LEN + 1) break;
            }
        }
    }
}
