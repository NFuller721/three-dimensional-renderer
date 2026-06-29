const raylib = @import("raylib");
const std = @import("std");

const parser = @import("three_dimensional_renderer");
const Model = parser.Model;

const WINDOW_TITLE = "raylib-zig [core] example - basic window";

const SCREEN_WIDTH = 2560;
const SCREEN_HEIGHT = 1440;

const TARGET_FPS = 240;
const ASPECT_RATIO = @as(f32, SCREEN_WIDTH) / @as(f32, SCREEN_HEIGHT);

pub fn main(init: std.process.Init) !void {
    raylib.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, WINDOW_TITLE);
    defer raylib.closeWindow();

    raylib.setTargetFPS(TARGET_FPS);

    var tokens: std.ArrayList(parser.Token) = .empty;
    defer tokens.deinit(init.gpa);

    try Model.tokenize(init.gpa, init.io, "examples/teapot.obj", &tokens);

    var teapot = try Model.parse(init.gpa, tokens.items);
    defer teapot.deinit(init.gpa);

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(.black);

        raylib.drawFPS(10, 10);
    }
}
