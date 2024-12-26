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

test "aligned allocation" {
    var buffer: [100]u8 = undefined;
    var allocator = FixedBufferAllocator.init(&buffer);

    const memory = allocator.alignedAlloc(10, 4) orelse {
        try testing.fail("failed to allocate memory");
        return;
    };

    const addr = @intFromPtr(&memory[0]);
    try testing.expect(addr % 4 == 0);
}
