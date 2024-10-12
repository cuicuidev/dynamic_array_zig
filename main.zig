const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var arr = try DynamicArray(u8).init(&allocator, 1);
    defer arr.deinit();

    try stdout.writeAll("Array created!\n\n");

    const arr_size = 32;
    var i: u8 = 0;
    var j: u8 = 0;

    try stdout.print("Populating the array with {} numbers\n\n", .{arr_size});

    while (i < arr_size) : (i += 1) {
        try arr.append(i);
        while (j < arr.pos) : (j += 1) {
            try stdout.print("{} ", .{arr.items[j]});
        }
        j = 0;
        try stdout.writeAll("\n");
    }

    i = 0;
    j = 0;

    try stdout.writeAll("\n\nRemoving the first item of the array iteratively until it's empty!\n\n");
    while (0 < arr.pos) {
        try arr.remove(0);
        while (j < arr.pos) : (j += 1) {
            try stdout.print("{} ", .{arr.items[j]});
        }
        j = 0;
        try stdout.writeAll("\n");
    }
}

fn DynamicArray(comptime T: type) type {
    return struct {
        items: []T,
        pos: usize,
        allocator: *std.mem.Allocator,

        const Self = @This();

        // Constructor
        pub fn init(allocator: *std.mem.Allocator, capacity: usize) !Self {
            return .{ .items = try allocator.*.alloc(T, capacity), .pos = 0, .allocator = allocator };
        }

        // Deallocates all memory used by the array
        pub fn deinit(self: *Self) void {
            try self.clear();
            try self.free();
        }

        // Adds an element to the end of the array
        pub fn append(self: *Self, value: T) !void {
            if (self.pos == self.items.len) {
                try self.upsize();
            }

            self.items[self.pos] = value;
            self.pos += 1;
        }

        // Doubles the array capacity
        fn upsize(self: *Self) !void {
            std.debug.print("Upsizing from {} to {}...\n", .{ self.items.len, self.items.len * 2 });

            var larger = try self.allocator.alloc(T, self.items.len * 2);

            @memcpy(larger[0..self.items.len], self.items);

            self.allocator.free(self.items);
            self.items = larger;
        }

        // Removes an element at a specified index
        pub fn remove(self: *Self, idx: usize) !void {
            const n_shifts: usize = self.pos - idx;
            var i: usize = idx;

            while (i < n_shifts) : (i += 1) {
                if (i + 1 < self.pos) {
                    self.items[i] = self.items[i + 1];
                } else {
                    self.items[i] = undefined;
                }
            }

            self.pos -= 1;

            if (self.pos == self.items.len / 2) {
                try self.downsize();
            }
        }

        // Decreases the array capacity by half
        fn downsize(self: *Self) !void {
            std.debug.print("Downsizing from {} to {}...\n", .{ self.items.len, self.items.len / 2 });

            var smaller = try self.allocator.alloc(T, self.items.len / 2);

            @memcpy(smaller[0..self.pos], self.items[0..self.pos]);

            self.allocator.free(self.items);
            self.items = smaller;
        }

        // Returns an element at a specified index
        // pub fn get(self: *Self, idx: usize) !*T {}

        // Removes an element at a specified index and returns it
        // pub fn pop(self: *Self, idx: ?usize) !T {}

        // Empties the array
        pub fn clear(self: *Self) !void {
            var i: usize = 0;
            while (i < self.pos) : (i += 1) {
                self.items[i] = undefined;
            }
            self.pos = 0;
        }

        // Frees all memory
        fn free(self: *Self) !void {
            self.allocator.free(self.items);
        }
    };
}
