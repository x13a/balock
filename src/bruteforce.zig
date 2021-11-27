const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;

const Sha256 = std.crypto.hash.sha2.Sha256;

const value_size: usize = Sha256.digest_length * 2;

pub fn bruteforce(hex1: []const u8, hex2: []const u8) !?[8]u8 {
    if (mem.replacementSize(u8, hex1, " ", "") != value_size or
        mem.replacementSize(u8, hex2, " ", "") != value_size)
    {
        return error.InvalidInput;
    }
    var v1: [value_size]u8 = undefined;
    var v2: [value_size]u8 = undefined;
    _ = mem.replace(u8, hex1, " ", "", &v1);
    _ = mem.replace(u8, hex2, " ", "", &v2);
    var checksum1: [Sha256.digest_length]u8 = undefined;
    var checksum2: [Sha256.digest_length]u8 = undefined;
    var buf1 = [_]u8{0} ** (value_size);
    var buf2 = [_]u8{0} ** 8;
    _ = try fmt.hexToBytes(&checksum1, &v1);
    _ = try fmt.hexToBytes(buf1[Sha256.digest_length..], &v2);
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
            _ = fmt.bufPrint(&result, "{d:0>8}", .{@intCast(u32, code)}) catch unreachable;
            return result;
        }
    }
    return null;
}

test "bruteforce" {
    const v1: []const u8 = "E3 EE B0 95 58 C9 6E 6C 45 63 CE 73 91 4C 32 F7 D2 EA 51 54 62 7A DF 3C 4B 86 A4 17 D7 F5 D0 C8";
    const v2: []const u8 = "B4 C0 E2 90 95 87 6F F6 05 10 C4 34 C0 1C 4C A4 CE 41 EB 20 57 77 33 EA 87 DC C4 79 E3 CE F5 3C";
    const result: []const u8 = "97979686";

    try std.testing.expectEqualSlices(u8, result, &(try bruteforce(v1, v2)).?);
}
