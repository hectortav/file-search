const std = @import("std");
const wz = @import("words.zig");
const s = @import("search.zig");
const h = @import("helpers.zig");
const io = std.io;
const os = std.os;
const Tuple = std.meta.Tuple;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn concatPaths(str1: []const u8, str2: []const u8) [s.max_filename_length]u8 {
    var str: [s.max_filename_length]u8 = [_:0]u8{0} ** s.max_filename_length;
    var i: usize = 0;
    while (i < str1.len) {
        str[i] = str1[i];
        i += 1;
    }
    var offset: usize = 0;
    if (str1[str1.len - 1] != '/') {
        str[i] = '/';
        i += 1;
        offset = 1;
    }
    while (i - str1.len - offset < str2.len) {
        str[i] = str2[i - str1.len - offset];
        i += 1;
    }
    return str;
}

pub fn getExtension(str: []const u8) ?[5]u8 {
    var i: usize = str.len - 1;
    var ext: [5]u8 = [_:0]u8{0} ** 5;
    // std.debug.print("{s}\n", .{str});
    while (i + 1 + 5 > str.len and i > 0) : (i -= 1) {
        if (str[i] == '.') {
            var j: usize = 0;
            i += 1;
            while (i < str.len) : (i += 1) {
                ext[j] = str[i];
                j += 1;
            }
            return ext;
        }
    }
    return null;
}

fn eql(comptime T: type, a: []const T, b: []const T) bool {
    var ai: usize = a.len - 1;
    var bi: usize = b.len - 1;
    while (a[ai] == 0) : (ai -= 1) {}
    while (b[bi] == 0) : (bi -= 1) {}
    if (ai != bi) return false;
    var i = ai;
    while (true) : (i -= 1) {
        if (a[i] != b[i]) return false;
        if (i == 0) break;
    }
    return true;
}

fn getFiles(
    allocator: *const Allocator,
    file_list: *ArrayList([s.max_filename_length]u8),
    dir: []const u8,
    to_include: ArrayList([]const u8),
) !u64 {
    var count: u64 = 0;
    var cur_dir = try std.fs.cwd().openIterableDir(dir, .{});
    defer cur_dir.close();

    var walker = try cur_dir.walk(allocator.*);
    defer walker.deinit();

    while (true) {
        if (walker.next()) |next_file| {
            if (next_file) |file| {
                // std.debug.print("{}: basename: '{s}' path: '{s}'\n", .{ file.kind, file.basename, file.path });
                if (file.basename[0] != '.') {
                    if (file.kind == .File) {
                        count += 1;
                        var extension = getExtension(file.basename);
                        if (extension) |ext| {
                            for (to_include.items) |e| {
                                // std.debug.print("{s} {s}\n", .{ e, ext });
                                if (eql(u8, e, &ext)) {
                                    try file_list.append(concatPaths(dir, file.path));
                                    break;
                                }
                            }
                        }
                    }
                }
                continue;
            }
            break;
        } else |err| {
            if (err != std.fs.Dir.OpenError.AccessDenied) {
                return err;
            }
        }
    }
    return count;
}

fn getUserInput(allocator: *const Allocator, input: *[]u8) !void {
    var buf: [250]u8 = undefined;

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        input.* = try allocator.alloc(u8, user_input.len);
        std.mem.copy(u8, input.*, user_input);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    if (args.len < 2) {
        try stdout.print("usage: {s} <directory_to_index>", .{args[0]});
        return;
    }

    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();

    // const allocator = arena.allocator();

    var search = s.Search.init(allocator);
    defer search.deinit();

    var file_list = ArrayList([s.max_filename_length]u8).init(allocator);
    defer file_list.deinit();

    var to_include = ArrayList([]const u8).init(allocator);
    defer to_include.deinit();

    try to_include.append("md");
    try to_include.append("txt");

    var index_timer = try std.time.Timer.start();
    const files_count = try getFiles(
        &allocator,
        &file_list,
        args[1],
        to_include,
    );

    for (file_list.items) |file_name| {
        // std.debug.print("{s}\n", .{file_name});
        const index = for (file_name) |char, i| {
            if (char == 0) break i;
        } else file_name.len;

        var file = try std.fs.cwd().openFile(file_name[0..index], .{});
        defer file.close();

        var words_list = wz.Words.init(allocator);
        defer words_list.deinit();

        // std.debug.print("{s}\n", .{file_name[0..index]});
        if (try words_list.indexFile(&allocator, file)) {
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
            try search.addFile(file_name);
        }
    }

    const stats = search.stats();
    try stdout.print("Searched {d} files\n", .{files_count});
    try stdout.print("Indexed {d} files\n", .{stats.files_len});
    try stdout.print("Found {d} words\n", .{stats.words_len});
    try stdout.print("In {}\n", .{std.fmt.fmtDuration(index_timer.read())});

    try stdout.print("\n~ Type a query or :q to quit ~\n", .{});
    while (true) {
        try stdout.print("\nSearch: ", .{});
        var query: []u8 = undefined;
        defer allocator.free(query);
        try getUserInput(&allocator, &query);
        if (query[0] != 0) {
            if (eql(u8, query, ":q")) break;

            var search_timer = try std.time.Timer.start();
            var results = ArrayList(Tuple(&.{ [s.max_filename_length]u8, f64 })).init(allocator);
            defer results.deinit();

            try search.search(&allocator, &results, query);

            try stdout.print("{d} results in {}\n", .{ results.items.len, std.fmt.fmtDuration(search_timer.read()) });
            var i: usize = 0;
            for (results.items) |res| {
                const file = res[0];
                const rank = res[1];
                try stdout.print("{s} ({d})\n", .{
                    file,
                    rank,
                });
                if (i > 10) break;
                i += 1;
            }
            std.debug.print("\n", .{});
        }
    }
}
