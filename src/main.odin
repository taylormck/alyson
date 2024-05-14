/**
 * @file Main file to boot up the game and run the loop
 */

package main

import "core:fmt"
import "core:os"
import SDL "vendor:sdl2"
import SDL_TTF "vendor:sdl2/ttf"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN | SDL.WINDOW_RESIZABLE

COLOR_WHITE :: SDL.Color{255, 255, 255, 255}

TextId :: enum {
	Title,
	SubTitle,
}

Text :: struct {
	text: ^SDL.Texture,
	dest: SDL.Rect,
}

Game :: struct {
	window:        ^SDL.Window,
	window_width:  i32,
	window_height: i32,
	renderer:      ^SDL.Renderer,
	font:          ^SDL_TTF.Font,
	font_size:     i32,
	texts:         [TextId]Text,
}

game := Game {
	window_width  = 1920,
	window_height = 1080,
	font_size     = 28,
}


main :: proc() {
	init_sdl()
	defer clean_sdl()

	game.texts[TextId.Title] = create_text("Testing", 3)
	game.texts[TextId.SubTitle] = create_text("One, Two, Three")

	event: SDL.Event

	game_loop: for {
		for SDL.PollEvent(&event) {
			if end_game(&event) {
				break game_loop
			}

			handle_events(&event)
		}

		title: Text = game.texts[TextId.Title]
		title.dest.x = game.window_width / 2 - title.dest.w / 2
		title.dest.y = game.window_height / 2 - title.dest.h
		SDL.RenderCopy(game.renderer, title.text, nil, &title.dest)

		sub_title: Text = game.texts[TextId.SubTitle]
		sub_title.dest.x = game.window_width / 2 - sub_title.dest.w / 2
		sub_title.dest.y = game.window_height / 2 - sub_title.dest.h
		SDL.RenderCopy(game.renderer, sub_title.text, nil, &sub_title.dest)

		draw_scene()
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

	game.font = SDL_TTF.OpenFont("assets/fonts/silver/Silver.ttf", game.font_size)
	if game.font == nil {
		fmt.eprintln("ERROR: Failed to load font: %s", SDL.GetErrorString())
		os.exit(1)
	}
}

clean_sdl :: proc() {
	SDL_TTF.Quit()
	SDL.Quit()
	SDL.DestroyWindow(game.window)
	SDL.DestroyRenderer(game.renderer)
}

handle_events :: proc(event: ^SDL.Event) {
	if event.type == SDL.EventType.WINDOWEVENT &&
	   event.window.windowID == SDL.GetWindowID(game.window) &&
	   event.window.event == SDL.WindowEventID.RESIZED {
		game.window_width = event.window.data1
		game.window_height = event.window.data2
	}

	if event.type != SDL.EventType.KEYDOWN && event.type != SDL.EventType.KEYUP {
		return
	}

	scancode := event.key.keysym.scancode

	#partial switch scancode {
	// TODO: implement this
	}

}

draw_scene :: proc() {
	SDL.RenderPresent(game.renderer)
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
	SDL.RenderClear(game.renderer)
}

create_text :: proc(str: cstring, scale: i32 = 1) -> Text {
	surface := SDL_TTF.RenderText_Solid(game.font, str, COLOR_WHITE)
	defer SDL.FreeSurface(surface)

	texture := SDL.CreateTextureFromSurface(game.renderer, surface)

	dest_rect := SDL.Rect{}
	SDL_TTF.SizeText(game.font, str, &dest_rect.w, &dest_rect.h)

	dest_rect.w *= scale
	dest_rect.h *= scale

	return Text{text = texture, dest = dest_rect}
}

end_game :: proc(event: ^SDL.Event) -> (exit: bool) {
	return event.type == SDL.EventType.QUIT || event.key.keysym.scancode == .ESCAPE
}
