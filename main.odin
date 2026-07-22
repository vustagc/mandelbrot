package main

import f "core:fmt"
import "core:math"
import "core:math/cmplx"
import rl "vendor:raylib"

Width :: 1000

// represents the range of belonging to set or not
points : [Width][Width]rl.Color

main :: proc() {
	rl.InitWindow(Width, Width, "Mandelbrot")
	defer rl.CloseWindow()

	calculate_set()

	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {
		update()
		draw()
	}
}

// Range, [-R/2, R/2]
R : f32 = 4

calculate_set :: proc() {
	for y := 0; y < Width; y += 1 {
		for x := 0; x < Width; x += 1 {
			nx := f32(x) / (Width / R) - R / 2
			ny := f32(y) / (Width / R) - R / 2
			points[y][x] = in_set(nx, ny)
		}
	}
}

in_set :: proc(x, y : f32) -> rl.Color {
	MaxIterations :: 255
	Boundary :: 10

	c := complex(x, y)
	z : complex64 = complex(0, 0)
	for i : u8 = 0; i < MaxIterations; i += 1 {
		z = z * z + c
		dist := math.pow(cmplx.real(z), 2) + math.pow(cmplx.imag(z), 2)
		if dist > R * R {
			return rl.Color{0, 0, i, i}
		}
	}

	// reached max iter without blowing up, probably in set
	return rl.BLACK
}

xoffset, yoffset : i32

step :: 10

update :: proc() {
	if rl.IsKeyDown(.W) do yoffset += step
	if rl.IsKeyDown(.S) do yoffset -= step
	if rl.IsKeyDown(.D) do xoffset -= step
	if rl.IsKeyDown(.A) do xoffset += step

	if rl.IsKeyDown(.SPACE) {
		R -= 0.5
		calculate_set()
	} else if rl.IsKeyDown(.BACKSPACE) {
		R += 0.5
		calculate_set()
	} else if rl.IsKeyDown(.EQUAL) {
		R = 4
		calculate_set()
	}
}

draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.RAYWHITE)

	for y : i32 = 0; y < Width; y += 1 {
		for x : i32 = 0; x < Width; x += 1 {
			if points[y][x] == rl.WHITE {
				continue
			}

			rl.DrawPixel(x + xoffset, y + yoffset, points[y][x])
		}
	}
}
