const std = @import("std");
const io = std.io;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Tuple = std.meta.Tuple;

fn is_binary(data: []const u8, len: usize) bool {
    var s = [_]u8{0};
    return std.mem.indexOf(u8, data[0..len], &s) != null;
}

pub const max_word_length: u8 = 25;

pub const Words = struct {
    words: ArrayList([max_word_length]u8),
    points: ArrayList(u32),
    count: u32,
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .words = ArrayList([max_word_length]u8).init(allocator),
            .points = ArrayList(u32).init(allocator),
            .count = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        self.words.deinit();
        self.points.deinit();
    }

    pub fn push(self: *Self, val: [max_word_length]u8) !void {
        const index = for (self.words.items, 0..) |w, i| {
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

    pub fn get(self: *Self, index: usize) ?Tuple(&.{ [max_word_length]u8, u32 }) {
        if (index >= self.len()) {
            return null;
        }
        return .{ self.words.items[index], self.points.items[index] };
    }

    pub fn indexFile(self: *Self, allocator: *const Allocator, file: std.fs.File) !bool {
        const file_size = try file.getEndPos();
        // const max_bytes = @intCast(usize, file_size);
        const contents = try allocator.alloc(u8, file_size);
        _ = try file.read(contents);
        defer allocator.free(contents);

        if (is_binary(contents, @min(250, file_size))) {
            return false;
        }

        var words = std.mem.split(u8, contents, " ");
        while (words.next()) |word| {
            if (word.len >= max_word_length) {
                // std.debug.print("[WARN]: skipping word with length {d}\nMax length is set to {d}\n", .{ word.len, max_word_length });
                continue;
            }
            var i: usize = 0;
            var clean_word: [max_word_length]u8 = [_:0]u8{0} ** max_word_length;
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

        return true;
    }
};
