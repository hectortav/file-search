const std = @import("std");
const io = std.io;
const os = std.os;
const wz = @import("words.zig");

const ArrayList = std.ArrayList;

fn indexFile(file_name: []const u8) !wz.Words {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());

    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var words_list = wz.Words.init(gpa.allocator());
    defer words_list.deinit();

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
                        try words_list.push(clean_word);
                        i = 0;
                    }
                }
            }
            if (i > 0) {
                try words_list.push(clean_word);
            }
        }
    }
    return words_list;
}
//
//pub fn main() !void {
//    var words_list = try indexFile("./build.zig");
//    // for (word_list.items) |word, i| {
//    //     std.debug.print("{d}: {s}\n", .{ points_list.items[i], word });
//    // }
//
//    std.debug.print("word count: {d}\n", .{words_list.count});
//}

pub fn main() void {
    var dir = std.fs.openIterableDirAbsolute("./", .{ .access_sub_paths = true }) catch unreachable;
    var iterator = dir.iterate();
    var it = iterator.next() catch |err| blk: {
        switch (err) {
            error.AccessDenied => std.log.err("AccessDenied at first iteration", .{}),
            error.SystemResources => std.log.err("SystemResources at first iteration", .{}),
            error.Unexpected => std.log.err("Unexpected at first iteration", .{}),
        }
        break :blk null;
    };

    std.log.warn("it: {s}", .{it.?.name});
}
