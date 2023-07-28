const std = @import("std");
const io = std.io;
const os = std.os;

const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());

    var file = try std.fs.cwd().openFile("./build.zig", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var word_list = ArrayList([25]u8).init(gpa.allocator());
    defer word_list.deinit();
    var points_list = ArrayList(u16).init(gpa.allocator());
    defer points_list.deinit();

    var word_count: u16 = 0;

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var words = std.mem.split(u8, line, " ");
        while (words.next()) |word| {
            var i: usize = 0;
            var clean_word: [25]u8 = [_:0]u8{0} ** 25;
            for (word) |char| {
                if (std.ascii.isAlphabetic(char) or std.ascii.isDigit(char)) {
                    clean_word[i] = char;
                    i += 1;
                } else {
                    if (i > 0) {
                        const word_index = for (word_list.items) |w, index| {
                            if (std.mem.eql(u8, &w, &clean_word)) break index;
                        } else null;

                        if (word_index) |wi| {
                            points_list.items[wi] += 1;
                        } else {
                            try word_list.append(clean_word);
                            try points_list.append(1);
                        }
                        i = 0;
                        word_count += 1;
                    }
                }
            }
            if (i > 0) {
                const word_index = for (word_list.items) |w, index| {
                    if (std.mem.eql(u8, &w, &clean_word)) break index;
                } else null;

                if (word_index) |wi| {
                    points_list.items[wi] = points_list.items[wi];
                } else {
                    try word_list.append(clean_word);
                    try points_list.append(1);
                }
                word_count += 1;
            }
        }
    }

    for (word_list.items) |word, i| {
        std.debug.print("{d}: {s}\n", .{ points_list.items[i], word });
    }

    std.debug.print("word count: {d}\n", .{word_count});
}
