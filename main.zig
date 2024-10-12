const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    const arr_size: usize = 8;

    var arr = try DynamicArray(usize).init(&allocator, 1);
    defer arr.deinit();

    try stdout.writeAll("Array created!\n\n");

    var i: usize = 0;
    var j: usize = 0;

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

    i = 0;
    j = 0;

    try stdout.print("Populating the array with {} numbers, again...\n\n", .{arr_size});

    while (i < arr_size) : (i += 1) {
        try arr.append(i);
        while (j < arr.pos) : (j += 1) {
            try stdout.print("{} ", .{arr.items[j]});
        }
        j = 0;
        try stdout.writeAll("\n");
    }

    const val_pop_null: usize = try arr.pop(null);
    const val_get_6: usize = arr.get(6).*;
    const val_pop_0: usize = try arr.pop(0);

    try stdout.print("\n\nPop null: {}\nGet 6: {}\nPop 0: {}\n", .{ val_pop_null, val_get_6, val_pop_0 });

    i = 0;
    j = 0;

    try stdout.print("Printing the array values...\n\n", .{});

    while (i < arr.pos) : (i += 1) {
        try stdout.print("{} ", .{arr.get(i).*});
    }

    try stdout.writeAll("\n");
}

// This is my custom dynamic array implementation
// I struggled a lot, even though I know how dynamic arrays work :(
//
// I use the function struct declaration syntax so I can set comptime params such as this generic.
// Maybe that is possible somehow using another approach, but this is the one I figured out.
fn DynamicArray(comptime T: type) type {
    return struct {
        items: []T, // The array itself
        pos: usize, // The "len" attribute
        allocator: *std.mem.Allocator,

        const Self = @This(); // This is neat, it helps me to type the self parameter using "Self" instead of "DynamicArray(T)"

        // This is the constructor and it's responsible of allocating the initial memory for the array as well as instantiating it.
        pub fn init(allocator: *std.mem.Allocator, capacity: usize) !Self {
            return .{ .items = try allocator.*.alloc(T, capacity), .pos = 0, .allocator = allocator };
        }

        // This clears the array and frees the memory, used in a defer statement.
        pub fn deinit(self: *Self) void {
            self.free();
        }

        // Adds an element of type T to the end of the array.
        pub fn append(self: *Self, value: T) !void {
            if (self.pos == self.items.len) {
                try self.upsize(); // If we run out of space, we upsize the array.
            }

            self.items[self.pos] = value;
            self.pos += 1;
        }

        // This method doubles the capacity of the array.
        fn upsize(self: *Self) !void {
            std.debug.print("Upsizing from {} to {}...\n", .{ self.items.len, self.items.len * 2 });

            // We allocate the necessary memory first.
            var larger = try self.allocator.alloc(T, self.items.len * 2);

            // We copy our current array to the new memory.
            @memcpy(larger[0..self.items.len], self.items);

            // Then we free the old allocated space and overwrite the items attribute to the new array that's double the size.
            self.allocator.free(self.items);
            self.items = larger;
        }

        // Removes an element at a specified index.
        pub fn remove(self: *Self, idx: usize) !void {
            // First, we compute the number of left shifts we ought to do.
            const n_shifts: usize = self.pos - idx;

            // Then we iterate over the array starting at the index
            var i: usize = idx;

            while (i < n_shifts) : (i += 1) {
                if (i + 1 < self.pos) {
                    // As long as we didn't reach the last item of the array, we overwrite this item with the next in line.
                    self.items[i] = self.items[i + 1];
                } else {
                    // If we reach the last one, we set is as undefined because it's already copied to the previous position.
                    self.items[i] = undefined;
                }
            }

            self.pos -= 1;

            // Finally we check if we can downsize.
            if (self.pos == self.items.len / 2) {
                try self.downsize();
            }
        }

        // Decreases the array capacity by half. Same logic as the upsizing, but the other way around.
        fn downsize(self: *Self) !void {
            // We don't downsize to a 0 sized array.
            if (self.items.len > 1) {
                std.debug.print("Downsizing from {} to {}...\n", .{ self.items.len, self.items.len / 2 });
                var smaller = try self.allocator.alloc(T, self.items.len / 2);

                @memcpy(smaller[0..self.pos], self.items[0..self.pos]);

                self.allocator.free(self.items);
                self.items = smaller;
            }
        }

        // Returns a pointer to an element at a specified index
        pub fn get(self: *Self, idx: usize) *T {
            return &self.items[idx];
        }

        // Removes an element at a specified index and returns it
        pub fn pop(self: *Self, idx: ?usize) !T {
            const i: usize = idx orelse self.pos - 1;

            const val: T = self.get(i).*;
            try self.remove(i);
            return val;
        }

        // Empties the array.
        pub fn clear(self: *Self) !void {
            var i: usize = 0;
            while (i < self.pos) : (i += 1) {
                self.items[i] = undefined;
            }
            self.pos = 0;
        }

        // Frees all memory
        fn free(self: *Self) void {
            self.allocator.free(self.items);
        }
    };
}
