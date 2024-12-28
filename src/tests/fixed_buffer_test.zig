const std = @import("std");
const testing = std.testing;
const FixedBufferAllocator = @import("../allocator/fixed_buffer.zig").FixedBufferAllocator;
const AllocationHeader = @import("../allocator/fixed_buffer.zig").AllocationHeader;
const AllocError = @import("../allocator/fixed_buffer.zig").AllocError;

test "basic aligned allocation" {
    var buffer: [100]u8 align(@alignOf(AllocationHeader)) = undefined;

    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = try allocator.alignedAlloc(10, 4);
    try testing.expect(@intFromPtr(&mem1[0]) % 4 == 0);
}

test "multiple aligned allocations" {
    var buffer: [100]u8 align(@alignOf(AllocationHeader)) = undefined;

    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = try allocator.alignedAlloc(10, 4);
    const mem2 = try allocator.alignedAlloc(20, 8);

    try testing.expect(@intFromPtr(&mem1[0]) % 4 == 0);
    try testing.expect(@intFromPtr(&mem2[0]) % 8 == 0);
}

test "alignment near buffer end" {
    var buffer: [100]u8 align(@alignOf(AllocationHeader)) = undefined;

    var allocator = FixedBufferAllocator.init(&buffer);

    _ = try allocator.alignedAlloc(70, 4);
    try testing.expectError(AllocError.OutOfMemory, allocator.alignedAlloc(70, 4));
}

test "allocation and deallocation" {
    var buffer: [200]u8 align(@alignOf(AllocationHeader)) = undefined;
    var allocator = FixedBufferAllocator.init(&buffer);

    const mem1 = try allocator.alignedAlloc(50, 8);
    _ = try allocator.alignedAlloc(25, 4);
    try allocator.free(mem1);

    const mem3 = try allocator.alignedAlloc(45, 8);
    try testing.expect(@intFromPtr(&mem3[0]) % 8 == 0);
    try testing.expect(mem3.len == 45);
}

test "merge free blocks - adjacent blocks" {
    var buffer: [300]u8 align(@alignOf(AllocationHeader)) = undefined;
    var allocator = FixedBufferAllocator.init(&buffer);
    _ = try allocator.alignedAlloc(50, 8);
    const mem2 = try allocator.alignedAlloc(50, 8);
    const mem3 = try allocator.alignedAlloc(50, 8);
    try allocator.free(mem2);
    try allocator.free(mem3);

    const large_mem = try allocator.alignedAlloc(90, 8);
    try testing.expect(large_mem.len == 90);
}
