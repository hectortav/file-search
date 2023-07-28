const std = @import("std");
const io = std.io;
const os = std.os;
const wordsFile = @import("words.zig");

const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());

    var file = try std.fs.cwd().openFile("./build.zig", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    const Words = wordsFile.Words();

    var words_list = Words.init(gpa.allocator());
    defer .words.deinit();

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
                        words_list.push(clean_word);
                        i = 0;
                    }
                }
            }
            if (i > 0) {
                words_list.push(clean_word);
            }
        }
    }

    // for (word_list.items) |word, i| {
    //     std.debug.print("{d}: {s}\n", .{ points_list.items[i], word });
    // }

    // std.debug.print("word count: {d}\n", .{word_count});
}
