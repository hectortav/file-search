const std = @import("std");
const wz = @import("words.zig");
const m = @import("map.zig");
const io = std.io;
const os = std.os;

const ArrayList = std.ArrayList;

const max_filename_length: u8 = 250;

fn literalToArr(literal: []const u8) [wz.max_word_length]u8 {
    var arr: [wz.max_word_length]u8 = [_:0]u8{0} ** wz.max_word_length;
    var i: usize = 0;
    while (i < literal.len) {
        arr[i] = literal[i];
        i += 1;
    }

    return arr;
}

fn indexFile(words_list: *wz.Words, file: std.fs.File) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

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
                        try words_list.*.push(clean_word);
                        i = 0;
                    }
                }
            }
            if (i > 0) {
                try words_list.*.push(clean_word);
            }
        }
    }
}

fn getFiles(allocator: *const std.mem.Allocator, file_list: *ArrayList([max_filename_length]u8), dir: []const u8) !void {
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
                        var slice: [max_filename_length]u8 = [_:0]u8{0} ** max_filename_length;
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
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(!gpa.deinit());
    // var allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var map = m.Map.init(allocator);
    defer map.deinit();

    // var filename: [250]u8 = [_:0]u8{0} ** 250;
    // i = 0;
    // while (i < "/filename".len) {
    //     filename[i] = "/filename"[i];
    //     i += 1;
    // }
    // try map.put(&allocator, "tests", "/filename", 10, 5);
    // if (map.get("tests")) |value| {
    //     std.debug.print("{s}\n", .{value});
    // } else {
    //     std.debug.print("not found\n", .{});
    // }

    var file_list = ArrayList([max_filename_length]u8).init(allocator);
    defer file_list.deinit();

    try getFiles(&allocator, &file_list, ".");

    for (file_list.items) |file_name| {
        // std.debug.print("{s}\n", .{file_name});
        const index = for (file_name) |char, i| {
            if (char == 0) break i;
        } else file_name.len;

        var file = try std.fs.cwd().openFile(file_name[0..index], .{});
        defer file.close();

        var words_list = wz.Words.init(allocator);
        defer words_list.deinit();

        try indexFile(&words_list, file);
        var word_count = words_list.count;
        // std.debug.print("word count: {d}\n", .{word_count});

        var i: usize = 0;
        while (words_list.get(i)) |tuple| {
            // std.debug.print("{s} {s} {d} {d}\n", .{ tuple[0], file_name, tuple[1], word_count });
            const word = tuple[0];
            const points = tuple[1];
            try map.put(&allocator, word, file_name, points, word_count);
            i += 1;
        }
    }

    if (map.get(literalToArr("tests"))) |res| {
        std.debug.print("tests: found in: {s}\n", .{res});
    }

    if (map.get(literalToArr("ArrayList"))) |res| {
        std.debug.print("ArrayList: found in: {s}\n", .{res});
    }
}
