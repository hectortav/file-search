const std = @import("std");
const io = std.io;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Tuple = std.meta.Tuple;

pub const max_word_length: u8 = 25;

pub const Words = struct {
    words: ArrayList([max_word_length]u8),
    points: ArrayList(u16),
    count: u16,
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .words = ArrayList([max_word_length]u8).init(allocator),
            .points = ArrayList(u16).init(allocator),
            .count = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        self.words.deinit();
        self.points.deinit();
    }

    pub fn push(self: *Self, val: [max_word_length]u8) !void {
        const index = for (self.words.items) |w, i| {
            if (std.mem.eql(u8, &w, &val)) break i;
        } else null;

        if (index) |i| {
            self.points.items[i] += 1;
        } else {
            try self.words.append(val);
            try self.points.append(1);
        }
        self.count += 1;
    }

    pub fn count(self: *Self) usize {
        return self.count;
    }

    pub fn len(self: *Self) usize {
        return self.words.items.len;
    }

    pub fn get(self: *Self, index: usize) ?Tuple(&.{ [max_word_length]u8, u16 }) {
        if (index >= self.len()) {
            return null;
        }
        return .{ self.words.items[index], self.points.items[index] };
    }

    pub fn indexFile(self: *Self, file: std.fs.File) !void {
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
                            try self.*.push(clean_word);
                            i = 0;
                        }
                    }
                }
                if (i > 0) {
                    try self.*.push(clean_word);
                }
            }
        }
    }
};
