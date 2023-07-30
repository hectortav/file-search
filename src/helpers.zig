const std = @import("std");
const s = @import("search.zig");
const wz = @import("words.zig");

pub fn literalToArrW(literal: []const u8) [wz.max_word_length]u8 {
    var arr: [wz.max_word_length]u8 = [_:0]u8{0} ** wz.max_word_length;
    std.mem.copy(u8, &arr, literal);

    return arr;
}

pub fn literalToArrF(literal: []const u8) [s.max_filename_length]u8 {
    var arr: [s.max_filename_length]u8 = [_:0]u8{0} ** s.max_filename_length;
    std.mem.copy(u8, &arr, literal);

    return arr;
}
