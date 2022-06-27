const std = @import("std");
const system = @import("system/registers.zig");

pub fn main() void {

    //TODO enable overall system clock
    system.RCC.AHB1ENR.modify(.{ .GPIOC = 1 }); //enable GPIOC clock
    system.GPIOC.MODER.modify(.{ .MODER10 = 0b01 }); //set GPIOC as output
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
