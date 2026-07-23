package main

import "base:builtin"
import "core:fmt"
import "core:math"
import "core:math/cmplx"
import "core:thread"
import "core:time"

import rl "vendor:raylib"

Width :: 1000

// represents the range of belonging to set or not
points: [Width][Width]rl.Color

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
R: f64 = 2

ThrData :: struct {
	ystart: i32,
	yend:   i32,
}

thr_calculate :: proc(data: rawptr) {
	d := cast(^ThrData)data

	for y := d.ystart; y < d.yend; y += 1 {
		for x := 0; x < Width; x += 1 {
			nx := f64(x) / (Width / R) - R / 2
			ny := f64(y) / (Width / R) - R / 2
			points[y][x] = in_set(nx, ny)
		}
	}

	free(d)
}

calculate_set :: proc() {
	//        // naive
	// start := time.now()
	// for y := 0; y < Width; y += 1 {
	// 	for x := 0; x < Width; x += 1 {
	// 		nx := f32(x) / (Width / R) - R / 2
	// 		ny := f32(y) / (Width / R) - R / 2
	// 		points[y][x] = in_set(nx, ny)
	// 	}
	// }
	// dur := time.since(start)
	// fmt.println("Took ", dur) // ~724ms on mac m4

	// multi-threaded
	NThreads :: 20
	Step :: Width / NThreads
	thrs: [NThreads]^thread.Thread

	start := time.now()
	for i: i32 = 0; i < NThreads; i += 1 {
		data := new(ThrData)
		data.ystart = i * Step
		data.yend = data.ystart + Step

		thrs[i] = thread.create_and_start_with_data(data, thr_calculate)
	}

	for t in thrs {
		thread.join(t)
	}

	// dur := time.since(start)
	// fmt.println("Took ", dur) // ~150ms on mac m4
}

in_set :: proc(x, y: f64) -> rl.Color {
	MaxIterations :: 255
	Boundary :: 10

	c := complex(x, y)
	z: complex128 = complex(0, 0)
	for i: u8 = 0; i < MaxIterations; i += 1 {
		z = z * z + c
		dist := math.pow(cmplx.real(z), 2) + math.pow(cmplx.imag(z), 2)
		if dist > 2 {
			return rl.Color{0, 0, i, i}
		}
	}

	// reached max iter without blowing up, probably in set
	return rl.BLACK
}

// xoffset, yoffset: i32
//
step :: 10

update :: proc() {
	// if rl.IsKeyDown(.W) {
	// 	yoffset += step
	// }
	// if rl.IsKeyDown(.S) {
	// 	yoffset -= step
	// 	calculate_set()
	// }
	// if rl.IsKeyDown(.D) {
	// 	xoffset -= step
	// 	calculate_set()
	// }
	// if rl.IsKeyDown(.A) {
	// 	xoffset += step
	// 	calculate_set()
	// }

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

	for y: i32 = 0; y < Width; y += 1 {
		for x: i32 = 0; x < Width; x += 1 {
			if points[y][x] == rl.WHITE {
				continue
			}

			rl.DrawPixel(x, y, points[y][x])
		}
	}
}

/*
   simd stuff, could be a way to optimize this somehow
fractional_propagation_delay_4 :: proc(
    input, delay_offset: #simd[4]f64,
    previous_input, previous_output: ^#simd[4]f64,
) -> #simd[4]f64 {

    k := simd.clamp(delay_offset, -0.49, 0.49)
    result : #simd[4]f64 = ---

    lt_lanes := simd.lanes_lt(k, 0.0)

    d0 := -k * input + (1 + k) * previous_input^
    d1 := (1 - k) * previous_input^ + k * previous_output^

    result = simd.select(lt_lanes, d0, d1)

    previous_output^ = previous_input^
    previous_input^ = input

    return result
}
   */
