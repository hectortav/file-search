const std = @import("std");
const io = std.io;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;

const max_filename_length: u8 = 250;
const max_word_length: u8 = 25;

const Value = struct {
    files: ArrayList([max_filename_length]u8),
    points: ArrayList(u16),
    count: ArrayList(u16),
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{ .files = ArrayList([max_filename_length]u8).init(allocator), .points = ArrayList(u16).init(allocator), .count = ArrayList(u16).init(allocator) };
    }

    pub fn deinit(self: *Self) void {
        for (self.files.items) |file, i| {
            std.debug.print("{s} {d} {d}\n", .{ file, self.points.items[i], self.count.items[i] });
        }
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
        try self.files.append(file);
        try self.points.append(points);
        try self.count.append(count);
    }

    pub fn get(self: Self) ?[max_filename_length]u8 {
        return self.files.items[0];
    }
};

pub const Map = struct {
    words: AutoHashMap([max_word_length]u8, Value),
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{ .words = AutoHashMap([max_word_length]u8, Value).init(allocator) };
    }

    pub fn deinit(self: *Self) void {
        // var it = self.words.valueIterator();
        // while (it.next()) |word| {
        //     word.deinit();
        // }
        self.words.deinit();
    }

    pub fn put(self: *Self, allocator: *const Allocator, word: [max_word_length]u8, file: [max_filename_length]u8, points: u16, count: u16) !void {
        var v = try self.words.getOrPut(word);

        if (!v.found_existing) {
            v.value_ptr.* = Value.init(allocator.*);
        }
        // std.debug.print("{s} {s} {d} {d}\n", .{ word, file, points, count });
        try v.value_ptr.*.push(file, points, count);
    }

    pub fn get(self: *Self, word: [max_word_length]u8) ?[max_filename_length]u8 {
        if (self.words.get(word)) |value| {
            return value.get();
        }
        return null;
    }
};
