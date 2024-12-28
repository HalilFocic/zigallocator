const std = @import("std");
const testing = std.testing;
const FixedBufferAllocator = @import("../allocator/fixed_buffer.zig").FixedBufferAllocator;
const AllocationHeader = @import("../allocator/fixed_buffer.zig").AllocationHeader;

test "basic aligned allocation" {
    var buffer: [100]u8 align(@alignOf(AllocationHeader)) = undefined;

    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = allocator.alignedAlloc(10, 4) orelse {
        return error.TestFailed;
    };
    try testing.expect(@intFromPtr(&mem1[0]) % 4 == 0);
}

test "multiple aligned allocations" {
    var buffer: [100]u8 align(@alignOf(AllocationHeader)) = undefined;

    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = allocator.alignedAlloc(10, 4) orelse return error.TestFailed;
    const mem2 = allocator.alignedAlloc(20, 8) orelse return error.TestFailed;

    try testing.expect(@intFromPtr(&mem1[0]) % 4 == 0);
    try testing.expect(@intFromPtr(&mem2[0]) % 8 == 0);
}

test "alignment near buffer end" {
    var buffer: [100]u8 align(@alignOf(AllocationHeader)) = undefined;

    var allocator = FixedBufferAllocator.init(&buffer);

    _ = allocator.alignedAlloc(70, 4) orelse return error.TestFailed;
    const mem2 = allocator.alignedAlloc(10, 8);
    try testing.expect(mem2 == null);
}

test "allocation and deallocation" {
    var buffer: [200]u8 align(@alignOf(AllocationHeader)) = undefined;
    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = allocator.alignedAlloc(50, 8) orelse return error.TestFailed;
    _ = allocator.alignedAlloc(25, 4) orelse return error.TestFailed;
    allocator.free(mem1);

    const mem3 = allocator.alignedAlloc(45, 8) orelse return error.TestFailed;
    try testing.expect(@intFromPtr(&mem3[0]) % 8 == 0);
    try testing.expect(mem3.len == 45);
}

test "merge free blocks - adjacent blocks" {
    var buffer: [300]u8 align(@alignOf(AllocationHeader)) = undefined;
    var first_header = @as(*AllocationHeader, @ptrCast(@alignCast(&buffer[0])));
    var allocator = FixedBufferAllocator.init(&buffer);
    _ = allocator.alignedAlloc(50, 8) orelse return error.TestFailed;
    first_header = @as(*AllocationHeader, @ptrCast(@alignCast(&buffer[0])));
    const mem2 = allocator.alignedAlloc(50, 8) orelse return error.TestFailed;
    const mem3 = allocator.alignedAlloc(50, 8) orelse return error.TestFailed;
    allocator.free(mem2);
    allocator.free(mem3);

    const large_mem = allocator.alignedAlloc(90, 8) orelse return error.TestFailed;
    try testing.expect(large_mem.len == 90);
}
