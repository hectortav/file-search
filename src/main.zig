const std = @import("std");
const wz = @import("words.zig");
const s = @import("search.zig");
const h = @import("helpers.zig");
const io = std.io;
const os = std.os;
const Tuple = std.meta.Tuple;

const ArrayList = std.ArrayList;

fn getFiles(allocator: *const std.mem.Allocator, file_list: *ArrayList([s.max_filename_length]u8), dir: []const u8) !void {
    var dir_list = ArrayList([]const u8).init(allocator.*);
    defer dir_list.deinit();

    try dir_list.append(dir);

    while (dir_list.items.len > 0) {
        const path = dir_list.pop();

        const dir_path = std.fs.realpathAlloc(allocator.*, path) catch null;
        if (dir_path) |p| {
            // std.debug.print("{s}\n", .{p});
            var cur_dir = try std.fs.cwd().openIterableDir(p, .{});
            defer cur_dir.close();
            defer (allocator.*).free(p);

            var it = cur_dir.iterate();
            while (try it.next()) |file| {
                if (file.name[0] != '.') {
                    if (file.kind == .File) {
                        var slice: [s.max_filename_length]u8 = [_:0]u8{0} ** s.max_filename_length;
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
    const allocator = gpa.allocator();
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();

    // const allocator = arena.allocator();

    var search = s.Search.init(allocator);
    defer search.deinit();

    var file_list = ArrayList([s.max_filename_length]u8).init(allocator);
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

        try words_list.indexFile(file);
        var word_count = words_list.count;
        // std.debug.print("word count: {d}\n", .{word_count});

        var i: usize = 0;
        while (words_list.get(i)) |tuple| {
            // std.debug.print("{s} {s} {d} {d}\n", .{ tuple[0], file_name, tuple[1], word_count });
            const word = tuple[0];
            const points = tuple[1];
            try search.put(&allocator, word, file_name, points, word_count);
            i += 1;
        }
    }
    var results = ArrayList(Tuple(&.{ [s.max_filename_length]u8, f64 })).init(allocator);
    defer results.deinit();
    try search.search(&allocator, &results,
        \\ if div Switch
    );

    for (results.items) |res| {
        const file = res[0];
        const rank = res[1];
        std.debug.print("{s} ({d})\n", .{
            file,
            rank,
        });
    }
}
