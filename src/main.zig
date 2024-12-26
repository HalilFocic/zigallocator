const std = @import("std");
const FixedBufferAllocator = @import("allocator/fixed_buffer.zig").FixedBufferAllocator;

pub const tests = @import("tests/fixed_buffer_test.zig");
pub fn main() !void {
    std.debug.print("Custom allocator test\n", .{});
}

test {
    std.testing.refAllDecls(@This());
}
