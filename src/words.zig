const std = @import("std");
const io = std.io;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn Words() type {
    return struct {
        words: ArrayList([25]u8),
        points: ArrayList(u16),
        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return Self{ .words = ArrayList([25]u8).init(allocator), .points = ArrayList(u16).init(allocator) };
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
            try self.words.append(val);
        }

        pub fn count(self: *Self) u16 {
            var sum: u16 = 0;
            for (self.points.items) |points| {
                sum += points;
            }
            return sum;
        }

        pub fn len(self: *Self) u16 {
            return self.words.items.len;
        }
    };
}

// test {
//     const expect = std.testing.expect;
//     const expectEqualStrings = std.testing.expectEqualStrings;
//
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer std.debug.assert(!gpa.deinit());
//
//     const StringStack = Stack([]const u8);
//
//     var words = StringStack.init(gpa.allocator());
//     defer.words.deinit();
//
//     try.words.push("hello");
//     try.words.push("world");
//     try.words.push("this is zig");
//
//     try expect.words.isEmpty() == false);
//
//     try expectEqualStrings.words.top().?, "this is zig");
//     try expectEqualStrings.words.pop().?, "this is zig");
//     try expectEqualStrings.words.top().?, "world");
//     try expectEqualStrings.words.pop().?, "world");
//     try expectEqualStrings.words.top().?, "hello");
//     try expectEqualStrings.words.pop().?, "hello");
//
//     try expect.words.isEmpty() == true);
// }
