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

	// TODO: Should maybe separate in-game.sprites and UI entities
	sprites:       [SpriteId]Sprite,
	input:         Input,
	fonts:         [FontFace]^SDL_TTF.Font,
}

init_game :: proc(game: ^Game) {
	load_fonts(game)
	create_text_sprites(game)
	player := create_player(game)
	game.sprites[SpriteId.Player] = player.sprite
}

update_game :: proc(game: ^Game, delta: f32) {
	player_horizontal_movement_input := get_axis(
		game.input.events[.move_left].value,
		game.input.events[.move_right].value,
	)

	game.sprites[SpriteId.Player].position.x +=
		player_horizontal_movement_input * player_speed * delta

	game.sprites[SpriteId.Player].destination.x = i32(game.sprites[SpriteId.Player].position.x)
}

draw_game :: proc(game: ^Game) {
	SDL.RenderPresent(game.renderer)
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
	SDL.RenderClear(game.renderer)

	// TODO: sort the entities into the desired draw order
	for &sprite in game.sprites {
		SDL.RenderCopy(game.renderer, sprite.texture, &sprite.source, &sprite.destination)
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
create_text :: proc(game: ^Game, str: cstring, font: FontFace, scale: i32 = 1) -> Sprite {
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
	return Sprite{texture = texture, destination = dest_rect, source = dest_rect}
}


// TODO: These should probably be factored out into a `scene.odin` file
@(private = "file")
create_text_sprites :: proc(game: ^Game) {
	title := create_text(game, "Testing", FontFace.Silver, 3)
	title.destination.x = game.window_width / 2 - title.destination.w / 2
	title.destination.y = game.window_height / 2 - title.destination.h

	sub_title := create_text(game, "One, Two, Three", FontFace.Silver)
	sub_title.destination.x = game.window_width / 2 - sub_title.destination.w / 2
	sub_title.destination.y = game.window_height / 2 - sub_title.destination.h

	game.sprites[SpriteId.Title] = title
	game.sprites[SpriteId.SubTitle] = sub_title
}
