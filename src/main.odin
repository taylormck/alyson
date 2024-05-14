/**
 * @file Main file to boot up the game and run the loop
 */

package main

import "core:fmt"
import "core:os"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"
import SDL_TTF "vendor:sdl2/ttf"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN | SDL.WINDOW_RESIZABLE

COLOR_WHITE :: SDL.Color{255, 255, 255, 255}

TextId :: enum {
	Title,
	SubTitle,
}

Text :: struct {
	texture: ^SDL.Texture,
	dest:    SDL.Rect,
}

EntityId :: enum {
	Player,
}

Entity :: struct {
	destination: SDL.Rect,
	source:      SDL.Rect,
	texture:     ^SDL.Texture,
}

Game :: struct {
	window:        ^SDL.Window,
	window_width:  i32,
	window_height: i32,
	renderer:      ^SDL.Renderer,
	font:          ^SDL_TTF.Font,
	font_size:     i32,
	texts:         [TextId]Text,
	entities:      [EntityId]Entity,
}

game := Game {
	window_width  = 1920,
	window_height = 1080,
	font_size     = 28,
}


main :: proc() {
	init_sdl()
	defer clean_sdl()

	create_player_entity()

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
		SDL.RenderCopy(game.renderer, title.texture, nil, &title.dest)

		sub_title: Text = game.texts[TextId.SubTitle]
		sub_title.dest.x = game.window_width / 2 - sub_title.dest.w / 2
		sub_title.dest.y = game.window_height / 2 - sub_title.dest.h
		SDL.RenderCopy(game.renderer, sub_title.texture, nil, &sub_title.dest)

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

	image_init := SDL_Image.Init(SDL_Image.INIT_PNG)
	if image_init == nil {
		fmt.eprintln("ERROR: Failed to initialize SDL Image: %s", SDL.GetErrorString())
		os.exit(1)
	}
}

clean_sdl :: proc() {
	SDL_TTF.Quit()
	SDL_Image.Quit()
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
}

draw_scene :: proc() {
	SDL.RenderPresent(game.renderer)
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
	SDL.RenderClear(game.renderer)
	SDL.RenderCopy(
		game.renderer,
		game.entities[EntityId.Player].texture,
		&game.entities[EntityId.Player].source,
		&game.entities[EntityId.Player].destination,
	)
}

create_text :: proc(str: cstring, scale: i32 = 1) -> Text {
	surface := SDL_TTF.RenderText_Solid(game.font, str, COLOR_WHITE)
	defer SDL.FreeSurface(surface)

	texture := SDL.CreateTextureFromSurface(game.renderer, surface)

	dest_rect := SDL.Rect{}
	SDL_TTF.SizeText(game.font, str, &dest_rect.w, &dest_rect.h)

	dest_rect.w *= scale
	dest_rect.h *= scale

	return Text{texture = texture, dest = dest_rect}
}

create_player_entity :: proc() {
	TEXTURE_PATH :: "assets/sprites/cat.png"

	texture := SDL_Image.LoadTexture(game.renderer, TEXTURE_PATH)
	if texture == nil {
		fmt.eprintln("ERROR: Failed to load the player texture: %s", SDL.GetErrorString())
		os.exit(1)
	}

	horizontal_padding: i32 = 7
	vertical_padding: i32 = 16

	horizontal_size: i32 = 16
	vertical_size: i32 = 16


	source := SDL.Rect {
		x = horizontal_padding,
		y = vertical_padding,
		w = horizontal_size,
		h = vertical_size,
	}

	destination := SDL.Rect {
		x = 20,
		y = game.window_height / 2,
		w = 200,
		h = 200,
	}

	// SDL.QueryTexture(texture, nil, nil, &destination.w, &destination.h)

	// TODO: reduce the source size, maybe ?
	game.entities[EntityId.Player] = Entity {
		destination = destination,
		source      = source,
		texture     = texture,
	}
}

end_game :: proc(event: ^SDL.Event) -> (exit: bool) {
	return event.type == SDL.EventType.QUIT || event.key.keysym.scancode == .ESCAPE
}
