const std = @import("std");
const wz = @import("words.zig");

pub fn literalToArr(literal: []const u8) [wz.max_word_length]u8 {
    var arr: [wz.max_word_length]u8 = [_:0]u8{0} ** wz.max_word_length;
    std.mem.copy(u8, &arr, literal);

    return arr;
}
