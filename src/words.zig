const std = @import("std");
const io = std.io;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const Words = struct {
    words: ArrayList([25]u8),
    points: ArrayList(u16),
    count: u16,
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{ .words = ArrayList([25]u8).init(allocator), .points = ArrayList(u16).init(allocator), .count = 0 };
    }

    pub fn deinit(self: *Self) void {
        self.words.deinit();
        self.points.deinit();
    }

    pub fn push(self: *Self, val: [25]u8) !void {
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

    pub fn count(self: *Self) u16 {
        return self.count;
    }

    pub fn len(self: *Self) u16 {
        return self.words.items.len;
    }
};
