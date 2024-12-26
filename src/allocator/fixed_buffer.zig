const std = @import("std");

pub const FixedBufferAllocator = struct {
    buffer: []u8,
    used: usize,
    aligned_used: usize,

    pub fn init(buffer: []u8) FixedBufferAllocator {
        return .{ .buffer = buffer, .used = 0, .aligned_used = 0 };
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
        const addr = @intFromPtr(&self.buffer[self.aligned_used]);
        const aligned_addr = std.mem.alignForward(addr, alignment);
        const padding = aligned_addr - addr;
        if (self.aligned_used + padding + size > self.buffer.len) {
            return null;
        }
        const start = self.aligned_used + padding;
        self.aligned_used += padding + size;
        return self.buffer[start .. start + size];
    }
};
