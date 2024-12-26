const std = @import("std");
const testing = std.testing;
const FixedBufferAllocator = @import("../allocator/fixed_buffer.zig").FixedBufferAllocator;

test "basic allocation" {
    var buffer: [1024]u8 = undefined;

    var allocator = FixedBufferAllocator.init(&buffer);

    const memory = allocator.alloc(100) orelse {
        try testing.fail("Failed to allocate memory");
        return;
    };
    try testing.expectEqual(@as(usize, 100), memory.len);
}
