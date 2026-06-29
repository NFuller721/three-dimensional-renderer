const std = @import("std");

pub const Point3 = [3]f32;
pub const Face = [3]Point3;

const TokenTag = enum {
    vertex,
    face,
};

pub const Token = union(TokenTag) {
    vertex: Point3,
    face: [3]u32,

    pub fn parse(tag: TokenTag, context: []const u8) !Token {
        switch (tag) {
            .vertex => return Token.parse_vertex(context),
            .face => return Token.parse_face(context),
        }
    }

    pub fn parse_vertex(context: []const u8) !Token {
        var iter = std.mem.splitScalar(u8, context, ' ');

        var point: Point3 = undefined;
        for (0..3) |idx| {
            const chunk = iter.next().?;
            point[idx] = try std.fmt.parseFloat(f32, chunk);
        }

        return .{ .vertex = point };
    }

    pub fn parse_face(context: []const u8) !Token {
        var iter = std.mem.splitScalar(u8, context, ' ');

        var face: [3]u32 = undefined;
        for (0..3) |idx| {
            const chunk = iter.next().?;
            const slash_idx = std.mem.indexOf(u8, chunk, "/") orelse chunk.len;

            face[idx] = try std.fmt.parseInt(u32, chunk[0..slash_idx], 10);
        }

        return .{ .face = face };
    }
};

const token_map = std.StaticStringMap(TokenTag).initComptime(.{
    .{ "v", .vertex },
    .{ "f", .face },
});

pub const Model = struct {
    faces: []Face,

    pub fn tokenize(
        allocator: std.mem.Allocator,
        io: std.Io,
        file_name: []const u8,
        tokens: *std.ArrayList(Token),
    ) !void {
        const fd = try std.Io.Dir.cwd().openFile(io, file_name, .{});
        defer fd.close(io);

        const file_size = try fd.length(io);
        const file_buffer = try allocator.alloc(u8, file_size);
        defer allocator.free(file_buffer);

        var file_reader = fd.reader(io, file_buffer);
        const reader = &file_reader.interface;

        while (try reader.takeDelimiter('\n')) |line| {
            var iter = std.mem.splitScalar(u8, line, ' ');
            const token_tag = token_map.get(iter.first()) orelse { continue; };
            const token = try Token.parse(token_tag, iter.rest());

            try tokens.append(allocator, token);
        }
    }

    pub fn parse(
        allocator: std.mem.Allocator,
        tokens: []const Token,
    ) !Model {
        var vertexes: std.ArrayList(Point3) = .empty;
        defer vertexes.deinit(allocator);

        var faces: std.ArrayList(Face) = .empty;
        defer faces.deinit(allocator);

        for (tokens) |token| {
            switch (token) {
                .vertex => |vertex| try vertexes.append(allocator, vertex),
                .face => |face| {
                    try faces.append(
                        allocator,
                        .{
                            vertexes.items[face[0] - 1],
                            vertexes.items[face[1] - 1],
                            vertexes.items[face[2] - 1],
                        },
                    );
                },
            }
        }

        return .{
            .faces = try faces.toOwnedSlice(allocator),
        };
    }

    pub fn deinit(self: *Model, allocator: std.mem.Allocator) void {
        allocator.free(self.faces);
        self.* = undefined;
    }
};
