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
            const aligned_start = std.mem.alignForward(usize, @intFromPtr(&self.buffer[data_start]), header.required_alignment) - @intFromPtr(&self.buffer[0]);
            const padding = aligned_start - data_start;

            if (@intFromPtr(&self.buffer[aligned_start]) == @intFromPtr(&memory[0])) {
                header.is_free = true;
                const next_offset = std.mem.alignForward(usize, current_offset + @sizeOf(AllocationHeader) + padding + header.size, @alignOf(AllocationHeader));
                if (next_offset < self.used) {
                    const next_header = @as(*AllocationHeader, @ptrCast(@alignCast(&self.buffer[next_offset])));
                    if (next_header.is_free) {
                        const next_data_start = next_offset + @sizeOf(AllocationHeader);
                        const next_aligned_start = std.mem.alignForward(usize, @intFromPtr(&self.buffer[next_data_start]), next_header.required_alignment);
                        const next_padding = next_aligned_start - @intFromPtr(&self.buffer[next_data_start]);
                        header.size += @sizeOf(AllocationHeader) + next_header.size + next_padding;
                    }
                }

                var prev_offset: usize = 0;
                while (prev_offset < current_offset) {
                    const prev_header = @as(*AllocationHeader, @ptrCast(@alignCast(&self.buffer[prev_offset])));
                    const prev_data_start = prev_offset + @sizeOf(AllocationHeader);
                    const prev_aligned_start = std.mem.alignForward(usize, prev_data_start, prev_header.required_alignment);
                    const prev_padding = prev_aligned_start - prev_data_start;
                    const block_size = @sizeOf(AllocationHeader) + prev_padding + prev_header.size;

                    const next_start = std.mem.alignForward(usize, prev_offset + block_size, @alignOf(AllocationHeader));
                    if (next_start == current_offset and prev_header.is_free) {
                        prev_header.size += @sizeOf(AllocationHeader) + padding + header.size;
                        break;
                    }
                    prev_offset = std.mem.alignForward(usize, prev_offset + block_size, @alignOf(AllocationHeader));
                }
                return;
            }
            current_offset = std.mem.alignForward(usize, current_offset + @sizeOf(AllocationHeader) + header.size, @alignOf(AllocationHeader));
        }
    }
};
