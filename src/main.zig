const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const os = std.os;
const path = std.fs.path;
const process = std.process;

const Sha256 = std.crypto.hash.sha2.Sha256;
const assert = std.debug.assert;
const print = std.debug.print;

const VERSION: []const u8 = "0.1.0";

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

pub fn bruteforce(allocator: *mem.Allocator, hex1: []const u8, hex2: []const u8) !?[8]u8 {
    const v1 = try mem.replaceOwned(u8, allocator, hex1, " ", "");
    defer allocator.free(v1);
    const v2 = try mem.replaceOwned(u8, allocator, hex2, " ", "");
    defer allocator.free(v2);
    assert(v1.len == v2.len);
    assert(v1.len == Sha256.digest_length * 2);
    var checksum1: [Sha256.digest_length]u8 = undefined;
    var checksum2: [Sha256.digest_length]u8 = undefined;
    var buf1 = [_]u8{0} ** (Sha256.digest_length * 2);
    var buf2 = [_]u8{0} ** 8;
    _ = try fmt.hexToBytes(&checksum1, v1);
    _ = try fmt.hexToBytes(buf1[Sha256.digest_length..], v2);
    var code: i32 = 9999_9999;
    while (code >= 0) : (code -= 1) {
        var i = code;
        var idx: usize = 7;
        while (idx >= 0) : (idx -= 1) {
            buf2[idx] = @intCast(u8, @mod(i, 10)) + 48;
            i = @divTrunc(i, 10);
            if (idx == 0) break;
        }
        Sha256.hash(&buf2, buf1[0..Sha256.digest_length], .{});
        Sha256.hash(&buf1, &checksum2, .{});
        if (mem.eql(u8, &checksum1, &checksum2)) {
            var result: [8]u8 = undefined;
            _ = try fmt.bufPrint(&result, "{d:0>8}", .{@intCast(u32, code)});
            return result;
        }
    }
    return null;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const opts = try getOpts(allocator);
    print("{s}", .{(try bruteforce(allocator, opts.hex1, opts.hex2)) orelse return error.NotFound});
}

test "bruteforce" {
    const v1: []const u8 = "E3 EE B0 95 58 C9 6E 6C 45 63 CE 73 91 4C 32 F7 D2 EA 51 54 62 7A DF 3C 4B 86 A4 17 D7 F5 D0 C8";
    const v2: []const u8 = "B4 C0 E2 90 95 87 6F F6 05 10 C4 34 C0 1C 4C A4 CE 41 EB 20 57 77 33 EA 87 DC C4 79 E3 CE F5 3C";
    const result: []const u8 = "97979686";

    try std.testing.expectEqualSlices(u8, result, &(try bruteforce(std.testing.allocator, v1, v2)).?);
}
