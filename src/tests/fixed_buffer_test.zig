const std = @import("std");
const testing = std.testing;
const FixedBufferAllocator = @import("../allocator/fixed_buffer.zig").FixedBufferAllocator;

test "basic aligned allocation" {
    var buffer: [100]u8 = undefined;
    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = allocator.alignedAlloc(10, 4) orelse {
        try testing.fail("Failed first allocation");
    };
    try testing.expect(@intFromPtr(&mem1[0]) % 4 == 0);
}

test "multiple aligned allocations" {
    var buffer: [100]u8 = undefined;
    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = allocator.alignedAlloc(10, 4) orelse return error.TestFailed;
    const mem2 = allocator.alignedAlloc(20, 8) orelse return error.TestFailed;

    try testing.expect(@intFromPtr(&mem1[0]) % 4 == 0);
    try testing.expect(@intFromPtr(&mem2[0]) % 8 == 0);
}

test "alignment near buffer end" {
    var buffer: [20]u8 = undefined;
    var allocator = FixedBufferAllocator.init(&buffer);

    _ = allocator.alignedAlloc(10, 4) orelse return error.TestFailed;
    const mem2 = allocator.alignedAlloc(10, 8);
    try testing.expect(mem2 == null);
}

test "allocation and deallocation" {
    var buffer: [1024]u8 = undefined;
    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = allocator.alignedAlloc(100, 8) orelse return error.TestFailed;
    _ = allocator.alignedAlloc(50, 4) orelse return error.TestFailed;

    allocator.free(mem1);

    const mem3 = allocator.alignedAlloc(90, 8) orelse return error.TestFailed;

    try testing.expect(@intFromPtr(&mem3[0]) % 8 == 0);
    try testing.expect(mem3.len == 90);
}
