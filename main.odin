package main

import "base:builtin"
import "core:fmt"
import "core:math"
import "core:math/cmplx"
import "core:strings"
import "core:thread"
import "core:time"

import rl "vendor:raylib"

Width :: 1000

Debug :: false

// represents the range of belonging to set or not
m_points: [Width][Width]rl.Color

State :: enum {
	mandelbrot,
	julia,
}

state := State.julia

// Range, [-R/2, R/2], Zoom factor
R: f64 = 4

xoffset: f64 = -R / 2
yoffset: f64 = -R / 2

// julia
j_points: [Width][Width]rl.Color
j_c := complex(0.0, 0.0)

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

ThrData :: struct {
	ystart: i32,
	yend:   i32,
}

thr_calculate :: proc(data: rawptr) {
	d := cast(^ThrData)data
	for y := d.ystart; y < d.yend; y += 1 {
		for x := 0; x < Width; x += 1 {
			nx := f64(x) / (Width / R) + xoffset
			ny := f64(y) / (Width / R) + yoffset

			if state == .mandelbrot {
				m_points[y][x] = m_in_set(nx, ny)
			} else {
				j_points[y][x] = j_in_set(nx, ny)
			}
		}
	}
	free(d)
}

calculate_set :: proc() {
	NThreads :: 20
	Step :: Width / NThreads
	thrs: [NThreads]^thread.Thread

	when Debug {
		start := time.now()
	}
	for i: i32 = 0; i < NThreads; i += 1 {
		data := new(ThrData)
		data.ystart = i * Step
		data.yend = data.ystart + Step

		thrs[i] = thread.create_and_start_with_data(data, thr_calculate)
	}

	for t in thrs {
		thread.join(t)
	}

	when Debug {
		fmt.println("Took,", time.since(start))
	}
}

m_in_set :: proc(x, y: f64) -> rl.Color {
	MaxIterations :: 50

	// turn this into a shader?

	c := complex(x, y)
	z: complex128 = complex(0, 0)
	for i: u8 = 0; i < MaxIterations; i += 1 {
		z = z * z + c
		dist := math.pow(cmplx.real(z), 2) + math.pow(cmplx.imag(z), 2)
		if dist > 2 {
			return rl.Color{0, 0, i, 0xFF}
		}
	}

	// reached max iter without blowing up, probably in set
	// return rl.BLACK
	return rl.Color{0, 0, u8(x) % 255, 0xFF}
}

j_in_set :: proc(x, y: f64) -> rl.Color {
	MaxIterations :: 100

	z: complex128 = complex(x, y)
	for i: u8 = 0; i < MaxIterations; i += 1 {
		z = z * z + j_c
		dist := math.pow(cmplx.real(z), 2) + math.pow(cmplx.imag(z), 2)
		if dist > 2 {
			return rl.Color{0, 0, i, i}
		}
	}

	// reached max iter without blowing up, probably in set
	// return rl.BLACK
	return rl.Color{0, 0, u8(math.abs(x) * 255), 0xFF}
}

step := R * 0.001

update :: proc() {
	if rl.IsKeyDown(.RIGHT) {
		j_c += complex(0.01, 0)
		calculate_set()
	}
	if rl.IsKeyDown(.LEFT) {
		j_c += complex(-0.01, 0)
		calculate_set()
	}
	if rl.IsKeyDown(.UP) {
		j_c += complex(0, -0.01)
		calculate_set()
	}
	if rl.IsKeyDown(.DOWN) {
		j_c += complex(0, 0.01)
		calculate_set()
	}

	if rl.IsKeyDown(.W) {
		yoffset -= step
		calculate_set()
	}
	if rl.IsKeyDown(.S) {
		yoffset += step
		calculate_set()
	}
	if rl.IsKeyDown(.D) {
		xoffset += step
		calculate_set()
	}
	if rl.IsKeyDown(.A) {
		xoffset -= step
		calculate_set()
	}

	if rl.IsKeyDown(.SPACE) {
		R -= step
		calculate_set()
	} else if rl.IsKeyDown(.BACKSPACE) {
		R += step
		calculate_set()
	} else if rl.IsKeyDown(.EQUAL) {
		R = 2
		calculate_set()
	}

}

draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.RAYWHITE)

	switch state {
	case .mandelbrot:
		for y: i32 = 0; y < Width; y += 1 {
			for x: i32 = 0; x < Width; x += 1 {
				if m_points[y][x] == rl.WHITE {
					continue
				}

				rl.DrawPixel(x, y, m_points[y][x])
			}
		}
	case .julia:
		for y: i32 = 0; y < Width; y += 1 {
			for x: i32 = 0; x < Width; x += 1 {
				if j_points[y][x] == rl.WHITE {
					continue
				}

				rl.DrawPixel(x, y, j_points[y][x])
			}
		}

		// nx := x / (Width / R) + xoffset
		// 1/x :=  (Width/R + xoffset) / nx

		cx := cmplx.real(j_c) * Width + Width / (R / 2)
		cy := cmplx.imag(j_c) * Width + Width / (R / 2)
		rl.DrawCircle(cast(i32)cx, cast(i32)cy, 4, rl.ORANGE)

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
