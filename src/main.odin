/**
 * @file Main file to boot up the game and run the loop
 */

package main

import "core:fmt"
import "core:os"
import "core:time"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"
import SDL_TTF "vendor:sdl2/ttf"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN | SDL.WINDOW_RESIZABLE

COLOR_WHITE :: SDL.Color{255, 255, 255, 255}

// Create the game object as a global
// This will serve as a way to access our singleton-like objects,
// such as the renderer, the audio server, etc.
game := Game {
	window_width  = 1920,
	window_height = 1080,
}

main :: proc() {
	init_sdl()
	defer clean_sdl()

	init_game(&game)

	event: SDL.Event

	prev_tick := time.tick_now()

	game_loop: for {
		for SDL.PollEvent(&event) {
			// Check for ending the game before processing other events
			if should_close_window(&event) {
				break game_loop
			}

			handle_events(&event)
		}

		// Update our clock
		new_tick := time.tick_now()
		duration := time.tick_diff(prev_tick, new_tick)
		prev_tick = new_tick
		delta := f32(time.duration_seconds(duration))

		// TODO: show separate game states, such as a splash, starting menu, etc.

		// New keyboard events are handled above along with other events.
		// However, this checks the current state of input devices, including
		// reporting which keyboard buttons are being held.
		check_input(&game.input)

		update_game(&game, delta)
		draw_game(&game)

		reset_input(&game.input)
	}
}

init_sdl :: proc() {
	sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
	if sdl_init_error != 0 {
		fmt.eprintfln("ERROR: Failed to initialize SDL: %s", SDL.GetErrorString())
		os.exit(1)
	}

	game.window = SDL.CreateWindow(
		"Alyson",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		game.window_width,
		game.window_height,
		WINDOW_FLAGS,
	)
	if game.window == nil {
		fmt.eprintln("ERROR: Failed to create window: %s", SDL.GetErrorString())
		os.exit(1)
	}

	game.renderer = SDL.CreateRenderer(game.window, -1, RENDER_FLAGS)
	if game.renderer == nil {
		fmt.eprintln("ERROR: Failed to create renderer: %s", SDL.GetErrorString())
		os.exit(1)
	}

	ttf_init_error := SDL_TTF.Init()
	if ttf_init_error != 0 {
		fmt.eprintln("ERROR: Failed to initialize SDL TTF: %s", SDL.GetErrorString())
		os.exit(1)
	}


	image_init := SDL_Image.Init(SDL_Image.INIT_PNG)
	if image_init == nil {
		fmt.eprintln("ERROR: Failed to initialize SDL Image: %s", SDL.GetErrorString())
		os.exit(1)
	}
}

clean_sdl :: proc() {
	SDL_Image.Quit()
	SDL_TTF.Quit()
	SDL.DestroyRenderer(game.renderer)
	SDL.DestroyWindow(game.window)
	SDL.Quit()
}

handle_events :: proc(event: ^SDL.Event) {
	if event.type == SDL.EventType.WINDOWEVENT &&
	   event.window.windowID == SDL.GetWindowID(game.window) &&
	   event.window.event == SDL.WindowEventID.RESIZED {
		game.window_width = event.window.data1
		game.window_height = event.window.data2

		// TODO: rescale the game to match the new window size
	}

	if event.type != SDL.EventType.KEYDOWN && event.type != SDL.EventType.KEYUP {
		return
	}

	handle_keyboard_event(&game.input, event.key.keysym.scancode)
}

should_close_window :: proc(event: ^SDL.Event) -> bool {
	return event.type == SDL.EventType.QUIT || event.key.keysym.scancode == .ESCAPE
}
