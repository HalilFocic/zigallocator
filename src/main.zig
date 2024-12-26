const std = @import("std");
const FixedBufferAllocator = @import("allocator/fixed_buffer.zig").FixedBufferAllocator;
pub fn main() !void {
    std.debug.print("Custom allocator test\n", .{});
}

test {
    std.testing.refAllDecls(@This());
}
const lib = @import("zigallocator_lib");
