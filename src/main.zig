const raylib = @import("raylib");
const std = @import("std");

const WINDOW_TITLE = "raylib-zig [core] example - basic window";
const TARGET_FPS = 240;
const SCREEN_WIDTH = 2560;
const SCREEN_HEIGHT = 1440;
const ASPECT_RATIO = @as(f32, SCREEN_WIDTH) / @as(f32, SCREEN_HEIGHT);

const Point3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn translate(self: Point3, dx: f32, dy: f32, dz: f32) Point3 {
        return .{ .x = self.x + dx, .y = self.y + dy, .z = self.z + dz };
    }

    pub fn rotate_xy(self: Point3, angle: f32) Point3 {
        const s = std.math.sin(angle);
        const c = std.math.cos(angle);

        return .{
            .x = (self.x * c) - (self.y * s),
            .y = (self.x * s) + (self.y * c),
            .z = self.z,
        };
    }

    pub fn rotate_yz(self: Point3, angle: f32) Point3 {
        const s = std.math.sin(angle);
        const c = std.math.cos(angle);

        return .{
            .x = self.x,
            .y = (self.y * c) - (self.z * s),
            .z = (self.y * s) + (self.z * c),
        };
    }

    pub fn rotate_xz(self: Point3, angle: f32) Point3 {
        const s = std.math.sin(angle);
        const c = std.math.cos(angle);

        return .{
            .x = (self.x * c) - (self.z * s),
            .y = self.y,
            .z = (self.x * s) + (self.z * c),
        };
    }

    pub fn project(self: Point3) Point2 {
        return .{
            .x = self.x / self.z,
            .y = self.y / self.z,
        };
    }
};

const Point2 = struct {
    x: f32,
    y: f32,

    pub fn viewport(self: Point2) ViewportPoint2 {
        return .{
            .x = @intFromFloat((self.x / ASPECT_RATIO + 1) / 2 * SCREEN_WIDTH),
            .y = @intFromFloat((1 - self.y) / 2 * SCREEN_HEIGHT),
        };
    }
};

const ViewportPoint2 = struct {
    x: i32,
    y: i32,
};

const Model = struct {
    center: Point3,
    xz_angle: f32,
    yz_angle: f32,
    xy_angle: f32,

    vertexes: []const Point3,
    faces: []const [3]u64,

    pub fn from_object_file(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, file_path: []const u8) !Model {
        const fd = try dir.openFile(io, file_path, .{});
        defer fd.close(io);

        var buffer: [4096]u8 = undefined;
        var file_reader = fd.reader(io, &buffer);
        const reader = &file_reader.interface;

        var vertexes = std.ArrayList(Point3).empty;
        errdefer vertexes.deinit(allocator);

        var faces = std.ArrayList([3]u64).empty;
        errdefer faces.deinit(allocator);

        while (try reader.takeDelimiter('\n')) |line| {
            var iter = std.mem.splitSequence(u8, line, " ");
            const ident = iter.next() orelse continue;

            if (std.mem.eql(u8, ident, "v")) {
                const x_str = iter.next() orelse continue;
                const x_f32 = try std.fmt.parseFloat(f32, x_str);

                const y_str = iter.next() orelse continue;
                const y_f32 = try std.fmt.parseFloat(f32, y_str);

                const z_str = iter.next() orelse continue;
                const z_f32 = try std.fmt.parseFloat(f32, z_str);

                try vertexes.append(allocator, .{ .x = x_f32, .y = y_f32, .z = z_f32 }); 
            } else if (std.mem.eql(u8, ident, "f")) {
                const p1_all = iter.next() orelse continue;
                var p1_iter = std.mem.splitSequence(u8, p1_all, "/");
                const p1_str = p1_iter.next() orelse continue;
                const p1_int = try std.fmt.parseInt(u64, p1_str, 10);

                const p2_all = iter.next() orelse continue;
                var p2_iter = std.mem.splitSequence(u8, p2_all, "/");
                const p2_str = p2_iter.next() orelse continue;
                const p2_int = try std.fmt.parseInt(u64, p2_str, 10);

                const p3_all = iter.next() orelse continue;
                var p3_iter = std.mem.splitSequence(u8, p3_all, "/");
                const p3_str = p3_iter.next() orelse continue;
                const p3_int = try std.fmt.parseInt(u64, p3_str, 10);

                try faces.append(allocator, .{ p1_int, p2_int, p3_int });
            } else continue;
        }

        return .{
            .center = .{ .x = 0, .y = 0, .z = 0 },
            .xz_angle = 0,
            .xy_angle = 0,
            .yz_angle = 0,
            .vertexes = try vertexes.toOwnedSlice(allocator),
            .faces = try faces.toOwnedSlice(allocator),
        };
    }

    pub fn render(self: *const Model) void {
        for (self.faces) |face| {
            const p1 = self.vertexes[face[0] - 1].rotate_xy(self.xy_angle).rotate_yz(self.yz_angle).rotate_xz(self.xz_angle).translate(self.center.x, self.center.y, self.center.z);
            const p2 = self.vertexes[face[1] - 1].rotate_xy(self.xy_angle).rotate_yz(self.yz_angle).rotate_xz(self.xz_angle).translate(self.center.x, self.center.y, self.center.z);
            const p3 = self.vertexes[face[2] - 1].rotate_xy(self.xy_angle).rotate_yz(self.yz_angle).rotate_xz(self.xz_angle).translate(self.center.x, self.center.y, self.center.z);

            if (p1.z <= 0) continue;
            if (p2.z <= 0) continue;
            if (p3.z <= 0) continue;

            const pt1 = p1.project().viewport();
            const pt2 = p2.project().viewport();
            const pt3 = p3.project().viewport();

            raylib.drawLine(pt1.x, pt1.y, pt2.x, pt2.y, .dark_green);
            raylib.drawLine(pt2.x, pt2.y, pt3.x, pt3.y, .dark_green);
            raylib.drawLine(pt3.x, pt3.y, pt1.x, pt1.y, .dark_green);
        }
    }
};

pub fn main(init: std.process.Init) !void {
    raylib.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, WINDOW_TITLE);
    defer raylib.closeWindow();

    raylib.setTargetFPS(TARGET_FPS);

    var armadillo = try Model.from_object_file(init.io, init.gpa, std.Io.Dir.cwd(), "examples/armadillo.obj");
    armadillo.center.x = 100.0;
    armadillo.center.z = 125.0;

    var teapot = try Model.from_object_file(init.io, init.gpa, std.Io.Dir.cwd(), "examples/teapot.obj");
    teapot.center.x = -4.0;
    teapot.center.z = 8.0;
    teapot.center.y = -2.0;

    var horse = try Model.from_object_file(init.io, init.gpa, std.Io.Dir.cwd(), "examples/horse.obj");
    horse.center.z = 0.20;
    horse.yz_angle = std.math.pi / -2.0;

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(.black);

        armadillo.render();
        teapot.render();
        horse.render();

        armadillo.xz_angle += 0.001 * 3;
        teapot.xz_angle += 0.001 * 3;
        horse.xz_angle += 0.001 * -3;

        raylib.drawFPS(10, 10);
    }
}
