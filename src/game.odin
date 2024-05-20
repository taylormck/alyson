package main

import "core:fmt"
import "core:os"
import "core:time"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"
import SDL_TTF "vendor:sdl2/ttf"

// TODO: Read this from a data file
player_speed :: 300.0

font_size :: 28

FontFace :: enum {
	Silver,
}

Game :: struct {
	window:        ^SDL.Window,
	window_width:  i32,
	window_height: i32,
	renderer:      ^SDL.Renderer,

	// TODO: the font should probably be on a per-text-entity basis
	font:          ^SDL_TTF.Font,

	// TODO: Should maybe separate in-game entities and UI entities
	entities:      [EntityId]Entity,
	input:         Input,
	fonts:         [FontFace]^SDL_TTF.Font,
}

init_game :: proc(game: ^Game) {
	load_fonts(game)
	create_text_entities(game)
	create_player_entity(game)
}

update_game :: proc(game: ^Game, delta: f32) {
	player_horizontal_movement_input := get_axis(
		game.input.events[.move_left].value,
		game.input.events[.move_right].value,
	)

	game.entities[EntityId.Player].position.x +=
		player_horizontal_movement_input * player_speed * delta

	game.entities[EntityId.Player].destination.x = i32(game.entities[EntityId.Player].position.x)
}

draw_game :: proc(game: ^Game) {
	SDL.RenderPresent(game.renderer)
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
	SDL.RenderClear(game.renderer)

	// TODO: sort the entities into the desired draw order
	for &entity in game.entities {
		SDL.RenderCopy(game.renderer, entity.texture, &entity.source, &entity.destination)
	}
}

@(private = "file")
load_fonts :: proc(game: ^Game) {
	game.fonts[FontFace.Silver] = SDL_TTF.OpenFont("assets/fonts/silver/Silver.ttf", font_size)
	if game.fonts[FontFace.Silver] == nil {
		fmt.eprintln("ERROR: Failed to load font Silver: %s", SDL.GetErrorString())
		os.exit(1)
	}
}

@(private = "file")
create_text :: proc(game: ^Game, str: cstring, font: FontFace, scale: i32 = 1) -> Entity {
	font_face := game.fonts[font]

	surface := SDL_TTF.RenderText_Solid(font_face, str, COLOR_WHITE)
	defer SDL.FreeSurface(surface)

	texture := SDL.CreateTextureFromSurface(game.renderer, surface)

	dest_rect := SDL.Rect{}
	SDL_TTF.SizeText(font_face, str, &dest_rect.w, &dest_rect.h)

	dest_rect.w *= scale
	dest_rect.h *= scale

	// We return destination and source rects that match here.
	// The caller should feel free to edit the destination rect, but leave
	// the source rect alone.
	return Entity{texture = texture, destination = dest_rect, source = dest_rect}
}


// TODO: These should probably be factored out into a `scene.odin` file
@(private = "file")
create_text_entities :: proc(game: ^Game) {
	title := create_text(game, "Testing", FontFace.Silver, 3)
	title.destination.x = game.window_width / 2 - title.destination.w / 2
	title.destination.y = game.window_height / 2 - title.destination.h

	sub_title := create_text(game, "One, Two, Three", FontFace.Silver)
	sub_title.destination.x = game.window_width / 2 - sub_title.destination.w / 2
	sub_title.destination.y = game.window_height / 2 - sub_title.destination.h

	game.entities[EntityId.Title] = title
	game.entities[EntityId.SubTitle] = sub_title
}

@(private = "file")
create_player_entity :: proc(game: ^Game) {
	TEXTURE_PATH :: "assets/sprites/cat.png"

	texture := SDL_Image.LoadTexture(game.renderer, TEXTURE_PATH)
	if texture == nil {
		fmt.eprintln("ERROR: Failed to load the player texture: %s", SDL.GetErrorString())
		os.exit(1)
	}

	position := Vec2{20.0, f32(game.window_width) / 2.0}

	horizontal_padding: i32 = 7
	vertical_padding: i32 = 16

	horizontal_size: i32 = 16
	vertical_size: i32 = 16

	// TODO: figure out how the hell to animate this

	source := SDL.Rect {
		x = horizontal_padding,
		y = vertical_padding,
		w = horizontal_size,
		h = vertical_size,
	}

	destination := SDL.Rect {
		x = 20,
		y = game.window_height / 2 - 100,
		w = 200,
		h = 200,
	}

	// TODO: reduce the source size, maybe ?
	game.entities[EntityId.Player] = Entity {
		destination = destination,
		source      = source,
		texture     = texture,
		position    = position,
	}
}
