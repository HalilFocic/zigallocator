const std = @import("std");

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
};
