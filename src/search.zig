const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const Tuple = std.meta.Tuple;
const wz = @import("words.zig");
const h = @import("helpers.zig");

pub const max_filename_length: u8 = 250;

const Value = struct {
    files: ArrayList([max_filename_length]u8), // the file
    points: ArrayList(u16), // the amount of times the word is in the file
    count: ArrayList(u16), // the length of the file in words
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .files = ArrayList([max_filename_length]u8).init(allocator),
            .points = ArrayList(u16).init(allocator),
            .count = ArrayList(u16).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        // for (self.files.items) |file, i| {
        //     std.debug.print("{s} {d} {d}\n", .{ file, self.points.items[i], self.count.items[i] });
        // }
        self.files.deinit();
        self.points.deinit();
        self.count.deinit();
    }

    pub fn push(self: *Self, file: [max_filename_length]u8, points: u16, count: u16) !void {
        const index = for (self.files.items) |f, i| {
            if (std.mem.eql(u8, &f, &file)) break i;
        } else null;

        if (index) |i| {
            _ = self.files.orderedRemove(i);
            _ = self.points.orderedRemove(i);
            _ = self.count.orderedRemove(i);
        }

        const our_tf = points / count;
        const idx = for (self.points.items) |p, i| {
            const their_tf = p / self.count.items[i];
            if (our_tf >= their_tf) break i;
        } else self.points.items.len;

        try self.files.insert(idx, file);
        try self.points.insert(idx, points);
        try self.count.insert(idx, count);
    }

    pub fn get(self: Self) ?Tuple(&.{ [max_filename_length]u8, f64, f64 }) {
        if (self.files.items.len == 0) {
            return null;
        }
        return .{
            self.files.items[0],
            @intToFloat(f64, self.points.items[0]) / @intToFloat(f64, self.count.items[0]),
            @intToFloat(f64, self.files.items.len), // the amount of files this word can be found in
        };
    }
};

pub const Search = struct {
    words: AutoHashMap([wz.max_word_length]u8, Value),
    files: ArrayList([max_filename_length]u8),
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .words = AutoHashMap([wz.max_word_length]u8, Value).init(allocator),
            .files = ArrayList([max_filename_length]u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var it = self.words.valueIterator();
        while (it.next()) |word| {
            word.deinit();
        }
        self.words.deinit();
        self.files.deinit();
    }

    pub fn addFile(self: *Self, file_name: []const u8) !void {
        try self.files.append(file_name);
    }

    pub fn put(self: *Self, allocator: *const Allocator, word: [wz.max_word_length]u8, file: [max_filename_length]u8, points: u16, count: u16) !void {
        var v = try self.words.getOrPut(word);

        if (!v.found_existing) {
            v.value_ptr.* = Value.init(allocator.*);
        }
        // std.debug.print("{s} {s} {d} {d}\n", .{ word, file, points, count });
        try v.value_ptr.*.push(file, points, count);
    }

    pub fn get(self: *Self, word: [wz.max_word_length]u8) ?Tuple(&.{ [max_filename_length]u8, f64 }) {
        if (self.words.get(word)) |value| {
            if (value.get()) |found| {
                const file_name = found[0];
                const tf = found[1];
                const idf = found[2] / (@intToFloat(f64, self.files.items.len) + 1.0);
                return .{
                    file_name,
                    tf * idf,
                };
            }
        }
        return null;
    }

    pub fn search(self: *Self, query: []const u8) !void {
        var tokens = std.mem.split(u8, query, " ");
        while (tokens.next()) |token| {
            if (self.get(h.literalToArr(token))) |found| {
                std.debug.print("{s}: {s} ({any})\n", .{ token, found[0], found[1] });
            }
        }
    }
};
