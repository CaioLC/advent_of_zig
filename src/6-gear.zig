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

const Symbol = struct {
    index: usize,
    l_number: ?usize,
    r_number: ?usize,
    is_gear: bool,
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./files/3-gears", .{});
    defer file.close();

    var buf: [LINE_LEN]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);

    var array_buf: [4000000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&array_buf);
    const allocator = fba.allocator();

    var symbols = ArrayList(Symbol).init(allocator);
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

        try parse_symbol(&buf, row, &symbols);
        try parse_number(&buf, row, &number_slices);
        fbs.reset();
        row += 1;
    }

    try neighbors(&number_slices, &symbols, &number);
    var total: usize = 0;
    for (symbols.items) |s| {
        if (s.is_gear) total += s.l_number.? * s.r_number.?;
    }
    print("total: {any}\n", .{total});
}

fn parse_symbol(line: []u8, row: usize, sym: *ArrayList(Symbol)) !void {
    for (line, 0..LINE_LEN) |c, index| {
        if (c == '.') continue;
        if (std.ascii.isDigit(c)) continue;
        try sym.append(Symbol{
            .index = index + row * LINE_LEN,
            .l_number = null,
            .r_number = null,
            .is_gear = false,
        });
    }
}

fn parse_number(line: []u8, row: usize, num: *ArrayList(Pointer)) !void {
    var start: ?usize = null;
    var end: ?usize = null;
    for (line, 0..LINE_LEN) |c, index| {
        if (std.ascii.isDigit(c)) {
            if (start) |_| {
                end = index + 1;
            } else {
                start = index;
                end = index + 1;
            }
        } else {
            try set_number(num, start, end, line, row);
            start = null;
            end = null;
        }
    }
    try set_number(num, start, end, line, row);
}

fn set_number(num: *ArrayList(Pointer), start: ?usize, end: ?usize, line: []u8, row: usize) !void {
    if (start) |s| {
        if (end) |e| {
            const numb = try std.fmt.parseUnsigned(usize, line[s..e], 0);
            try num.append(Pointer{
                .number = numb,
                .start = s + row * LINE_LEN,
                .end = e + row * LINE_LEN,
            });
            return;
        }
        unreachable;
    }
}

fn add_number(sym: *Symbol, numb: Pointer) void {
    if (sym.r_number) |_| {
        sym.is_gear = false;
        return;
    }
    if (sym.l_number) |_| {
        sym.r_number = numb.number;
        sym.is_gear = true;
        return;
    }
    sym.l_number = numb.number;
    return;
}

fn neighbors(num: *ArrayList(Pointer), sym: *ArrayList(Symbol), res: *ArrayList(usize)) !void {
    num_loop: for (num.items) |n| {
        const left = @subWithOverflow(n.start, 1)[0];
        const right = n.end;
        for (sym.items) |*s| {
            if (s.index == left or s.index == right) {
                try res.append(n.number);
                add_number(s, n);
                continue :num_loop;
            }
            if (s.index > right) break;
        }

        // if not inline, we check above or below:
        for (n.start..n.end) |p| {
            for (sym.items) |*s| {
                if (s.index == @subWithOverflow(p, LINE_LEN - 1)[0] or
                    s.index == @subWithOverflow(p, LINE_LEN)[0] or
                    s.index == @subWithOverflow(p, LINE_LEN + 1)[0] or
                    s.index == p + LINE_LEN - 1 or
                    s.index == p + LINE_LEN or
                    s.index == p + LINE_LEN + 1)
                {
                    try res.append(n.number);
                    add_number(s, n);
                    continue :num_loop;
                }
                if (s.index > p + LINE_LEN + 1) break;
            }
        }
    }
}
