const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Target STM32F401RE
    const target = .{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        .os_tag = .freestanding,
        .abi = .eabihf,
    };

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const elf = b.addExecutable("space_invaders", "src/startup.zig");
    elf.setTarget(target);
    elf.setBuildMode(mode);

    const vectors = b.addObject("vector", "src/system/vector.zig");
    vectors.setTarget(target);
    vectors.setBuildMode(mode);

    elf.addObject(vectors);
    elf.setLinkerScriptPath(.{ .path = "src/system/linker.ld" });

    const bin = b.addInstallRaw(elf, "space_invaders.bin", .{});
    const bin_step = b.step("bin", "Generate binary...");
    bin_step.dependOn(&bin.step);

    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        "st-flash",
        "write",
        b.getInstallPath(bin.dest_dir, bin.dest_filename),
        "0x8000000",
    });

    flash_cmd.step.dependOn(&bin.step);
    const flash_step = b.step("flash", "Flash and run the app on the STM32F401RE");
    flash_step.dependOn(&flash_cmd.step);

    b.default_step.dependOn(&elf.step);
    b.installArtifact(elf);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
