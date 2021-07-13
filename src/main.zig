const std = @import("std");
const mem = std.mem;
const os = std.os;
const path = std.fs.path;
const process = std.process;

const bruteforce = @import("bruteforce.zig").bruteforce;
const print = std.debug.print;

const VERSION: []const u8 = "0.2.0";

const Exit = enum(u8) {
    success = 0,
    usage = 2,
};

const Flag = struct {
    const help: []const u8 = "h";
    const version: []const u8 = "V";
};

const Opts = struct {
    hex1: []const u8 = "",
    hex2: []const u8 = "",
};

fn exit(code: Exit) noreturn {
    os.exit(@enumToInt(code));
}

fn getOpts(allocator: *mem.Allocator) !Opts {
    var opts = Opts{};
    var args = process.args();
    var prog_name = try (args.next(allocator) orelse return error.Invalid);
    defer allocator.free(prog_name);
    while (args.next(allocator)) |arg_or_err| {
        const arg = try arg_or_err;
        if (!mem.startsWith(u8, arg, "-")) {
            if (opts.hex1.len == 0) {
                opts.hex1 = arg;
                continue;
            }
            opts.hex2 = arg;
            break;
        }
        const flag = arg[1..];
        if (mem.eql(u8, flag, Flag.help)) {
            printUsage(prog_name);
            exit(.success);
        } else if (mem.eql(u8, flag, Flag.version)) {
            print("{s}", .{VERSION});
            exit(.success);
        }
        allocator.free(arg);
    }
    if (opts.hex1.len == 0 or opts.hex2.len == 0) {
        print("invalid hex", .{});
        exit(.usage);
    }
    return opts;
}

fn printUsage(exe: []const u8) void {
    const usage =
        \\{[exe]s} [-{[h]s}|{[V]s}] <HEX1> <HEX2>
        \\
        \\[-{[h]s}] * Print help and exit
        \\[-{[V]s}] * Print version and exit
    ;
    print(usage, .{ .exe = path.basename(exe), .h = Flag.help, .V = Flag.version });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const opts = try getOpts(&arena.allocator);
    print("{s}", .{(try bruteforce(opts.hex1, opts.hex2)) orelse return error.NotFound});
}
