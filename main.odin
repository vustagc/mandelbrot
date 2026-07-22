package main

import "core:math"
import rl "vendor:raylib"

Width :: 1000

// represents the range of belonging to set or not
points : [Width][Width]rl.Color

main :: proc() {
	rl.InitWindow(Width, Width, "Mandelbrot")
	defer rl.CloseWindow()

	init()

	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {
		update()
		draw()
	}
}

// Range, [-R/2, R/2]
R :: 4

init :: proc() {
	for y := 0; y < Width; y += 1 {
		for x := 0; x < Width; x += 1 {
			nx := f32(x) / (Width / R) - R / 2
			ny := f32(y) / (Width / R) - R / 2
			points[y][x] = in_set(nx, ny)
		}
	}
}

in_set :: proc(x, y : f32) -> rl.Color {
	MaxIterations :: 200
	Boundary :: 10
	// C :: 0

	z : f32 = 0
	zx : f32 = 0
	zy : f32 = 0

	// c := complex(x,y)
	for i := 0; i < MaxIterations; i += 1 {
		zx0 := zx * zx - zy * zy + x
		zy = zx * zy + zy * zx + y
		zx = zx0

		if zx * zx + zy * zy > R * R {
			// blows up, not in set
			return rl.WHITE
		}
	}

	// reached max iter without blowing up, probably in set
	return rl.BLACK
}

update :: proc() {
}

draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.WHITE)

	for y : i32 = 0; y < Width; y += 1 {
		for x : i32 = 0; x < Width; x += 1 {
			if points[y][x] == rl.WHITE {
				continue
			}

			rl.DrawPixel(x, y, points[y][x])
		}
	}
}
