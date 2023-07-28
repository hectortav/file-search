const std = @import("std");
const io = std.io;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn Stack(comptime T: type) type {
    return struct {
        stack: ArrayList(T),
        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return Self{ .stack = ArrayList(T).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.stack.deinit();
        }

        pub fn push(self: *Self, val: T) !void {
            try self.stack.append(val);
        }

        pub fn pop(self: *Self) ?T {
            return self.stack.popOrNull();
        }

        pub fn count(self: *Self) usize {
            return self.stack.items.len;
        }

        pub fn top(self: *Self) ?T {
            if (self.count() == 0) {
                return null;
            }
            return self.stack.items[self.count() - 1];
        }

        pub fn isEmpty(self: *Self) bool {
            return self.count() == 0;
        }
    };
}

test {
    const expect = std.testing.expect;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());

    const IntStack = Stack(i32);

    var stack = IntStack.init(gpa.allocator());
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    try expect(stack.isEmpty() == false);

    try expect(stack.top().? == 3);
    try expect(stack.pop().? == 3);
    try expect(stack.top().? == 2);
    try expect(stack.pop().? == 2);
    try expect(stack.top().? == 1);
    try expect(stack.pop().? == 1);

    try expect(stack.isEmpty() == true);
}

test {
    const expect = std.testing.expect;
    const expectEqualStrings = std.testing.expectEqualStrings;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());

    const StringStack = Stack([]const u8);

    var stack = StringStack.init(gpa.allocator());
    defer stack.deinit();

    try stack.push("hello");
    try stack.push("world");
    try stack.push("this is zig");

    try expect(stack.isEmpty() == false);

    try expectEqualStrings(stack.top().?, "this is zig");
    try expectEqualStrings(stack.pop().?, "this is zig");
    try expectEqualStrings(stack.top().?, "world");
    try expectEqualStrings(stack.pop().?, "world");
    try expectEqualStrings(stack.top().?, "hello");
    try expectEqualStrings(stack.pop().?, "hello");

    try expect(stack.isEmpty() == true);
}
