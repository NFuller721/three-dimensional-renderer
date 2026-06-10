const std = @import("std");
const rl = @import("raylib");

const SCREEN_HEIGHT: f64 = 720.0;
const SCREEN_WIDTH: f64 = 720.0;

const Point3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn translate_z(self: Point3, dz: f32) Point3 {
        return Point3 {
            .x = self.x,
            .y = self.y,
            .z = self.z + dz,
        };
    }

    pub fn rotate_xz(self: Point3, angle: f32) Point3 {
        const s = std.math.sin(angle);
        const c = std.math.cos(angle);

        return Point3 {
            .x = (self.x * c) - (self.z * s),
            .y = self.y,
            .z = (self.x * s) + (self.z * c),
        };
    }

    pub fn project(self: Point3) Point2 {
        return Point2 {
            .x = self.x / self.z,
            .y = self.y / self.z,
        };
    }
};

const Point2 = struct {
    x: f32,
    y: f32,

    pub fn scale(self: Point2) Point2Scaled {
        return Point2Scaled {
            .x = @intFromFloat((self.x + 1)/2 * SCREEN_WIDTH),
            .y = @intFromFloat((self.y + 1)/2 * SCREEN_HEIGHT),
        };
    }

    pub fn render(self: Point2) void {
        const scaled = self.scale();
        rl.drawRectangle(scaled.x, scaled.y, 8, 8, rl.Color.green);
    }
};

const Point2Scaled = struct {
    x: i32,
    y: i32,
};

const VERTEXES = [_]Point3 {
    Point3 {
        .x = -0.25,
        .y = -0.25,
        .z =  0.25,
    },
    Point3 {
        .x =  0.25,
        .y = -0.25,
        .z =  0.25,
    },
    Point3 {
        .x =  0.25,
        .y =  0.25,
        .z =  0.25,
    },
    Point3 {
        .x = -0.25,
        .y =  0.25,
        .z =  0.25,
    },
    Point3 {
        .x = -0.25,
        .y = -0.25,
        .z = -0.25,
    },
    Point3 {
        .x =  0.25,
        .y = -0.25,
        .z = -0.25,
    },
    Point3 {
        .x = -0.25,
        .y =  0.25,
        .z = -0.25,
    },
    Point3 {
        .x =  0.25,
        .y =  0.25,
        .z = -0.25,
    },
};

const INDICIES = [_][2]u32 {
    .{ 0, 1 },
    .{ 1, 2 },
    .{ 2, 3 },
    .{ 3, 0 },
    .{ 4, 5 },
    .{ 5, 7 },
    .{ 7, 6 },
    .{ 6, 4 },
    .{ 0, 4 },
    .{ 1, 5 },
    .{ 2, 7 },
    .{ 3, 6 },
};

pub fn draw_box(angle: f32) void {
    for (INDICIES) |face| {
        const p1 = VERTEXES[face[0]].rotate_xz(angle).translate_z(1.0).project().scale();
        const p2 = VERTEXES[face[1]].rotate_xz(angle).translate_z(1.0).project().scale();

        rl.drawLine(p1.x, p1.y, p2.x, p2.y, rl.Color.blue);
    }
}

pub fn main() anyerror!void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var angle: f32 = 0.0;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        draw_box(angle);

        angle += 0.01;
    }
}
