const std = @import("std");
pub const AllocationHeader = struct {
    size: usize,
    is_free: bool,
    required_alignment: usize,
};
pub const FixedBufferAllocator = struct {
    buffer: []u8,
    used: usize,

    pub fn init(buffer: []u8) FixedBufferAllocator {
        return .{ .buffer = buffer, .used = 0 };
    }

    pub fn alloc(self: *FixedBufferAllocator, size: usize) ?[]u8 {
        if (self.used + size > self.buffer.len) {
            return null;
        }

        const start = self.used;
        self.used += size;
        return self.buffer[start .. start + size];
    }

    pub fn alignedAlloc(self: *FixedBufferAllocator, size: usize, alignment: usize) ?[]u8 {
        const header_size = @sizeOf(AllocationHeader);
        const total_size = header_size + size;

        var current_offset: usize = 0;
        while (current_offset < self.used) {
            const header = @as(*AllocationHeader, @ptrCast(@alignCast(&self.buffer[current_offset])));
            if (header.is_free and header.size >= size) {
                header.is_free = false;
                header.size = size;
                header.required_alignment = alignment;

                const data_start = current_offset + header_size;
                const aligned_start = std.mem.alignForward(usize, @intFromPtr(&self.buffer[data_start]), alignment);
                const padding = aligned_start - @intFromPtr(&self.buffer[data_start]);
                return self.buffer[data_start + padding .. data_start + padding + size];
            }
            current_offset += header_size + header.size;
            current_offset = std.mem.alignForward(usize, current_offset, @alignOf(AllocationHeader));
        }

        if (current_offset + total_size > self.buffer.len) {
            return null;
        }
        const header = @as(*AllocationHeader, @ptrCast(@alignCast(&self.buffer[current_offset])));
        header.* = .{ .size = size, .is_free = false, .required_alignment = alignment };

        const data_start = current_offset + header_size;
        const aligned_start = std.mem.alignForward(usize, data_start, alignment);
        const padding = aligned_start - data_start;

        self.used = current_offset + total_size + padding;
        return self.buffer[data_start + padding .. data_start + padding + size];
    }

    pub fn free(self: *FixedBufferAllocator, memory: []u8) void {
        var current_offset: usize = 0;
        while (current_offset < self.used) {
            const header = @as(*AllocationHeader, @ptrCast(@alignCast(&self.buffer[current_offset])));
            const data_start = current_offset + @sizeOf(AllocationHeader);

            const aligned_start = std.mem.alignForward(usize, @intFromPtr(&self.buffer[data_start]), header.required_alignment);
            const padding = aligned_start - data_start;

            if (aligned_start == @intFromPtr(&memory[0])) {
                header.is_free = true;
                return;
            }

            current_offset += @sizeOf(AllocationHeader) + padding + header.size;
        }
    }
};
