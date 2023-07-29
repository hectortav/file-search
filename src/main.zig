const std = @import("std");
const wz = @import("words.zig");
const io = std.io;
const os = std.os;

const ArrayList = std.ArrayList;

fn indexFile(allocator: *std.mem.Allocator, file: std.fs.File) !wz.Words {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var words_list = wz.Words.init(allocator.*);
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

fn getFiles(allocator: *std.mem.Allocator, file_list: *ArrayList([250]u8), dir: []const u8) !void {
    var dir_list = ArrayList([]const u8).init(allocator.*);
    defer dir_list.deinit();

    try dir_list.append(dir);

    while (dir_list.items.len > 0) {
        const path = dir_list.pop();

        const dir_path = std.fs.realpathAlloc(allocator.*, path) catch null;
        if (dir_path) |p| {
            var cur_dir = try std.fs.cwd().openIterableDir(p, .{});
            defer cur_dir.close();
            defer (allocator.*).free(p);

            var it = cur_dir.iterate();
            while (try it.next()) |file| {
                if (file.name[0] != '.') {
                    if (file.kind == .File) {
                        var slice: [250]u8 = [_:0]u8{0} ** 250;
                        var i: usize = 0;
                        while (i < p.len) {
                            slice[i] = p[i];
                            i += 1;
                        }
                        slice[i] = '/';
                        i += 1;
                        while (i - p.len - 1 < file.name.len) {
                            slice[i] = file.name[i - p.len - 1];
                            i += 1;
                        }
                        try file_list.append(slice);
                    }
                    if (file.kind == .Directory and !std.mem.eql(u8, file.name, "zig-cache")) {
                        try dir_list.append(file.name);
                    }
                }
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    var allocator = gpa.allocator();

    var file_list = ArrayList([250]u8).init(allocator);
    defer file_list.deinit();

    try getFiles(&allocator, &file_list, ".");

    for (file_list.items) |file_name| {
        std.debug.print("{s}\n", .{file_name});
        const index = for (file_name) |char, i| {
            if (char == 0) break i;
        } else file_name.len;

        var file = try std.fs.cwd().openFile(file_name[0..index], .{});
        defer file.close();

        var words_list = try indexFile(&allocator, file);
        // for (word_list.items) |word, i| {
        //     std.debug.print("{d}: {s}\n", .{ points_list.items[i], word });
        // }

        std.debug.print("word count: {d}\n", .{words_list.count});
    }
}
