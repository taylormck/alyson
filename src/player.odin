package main

import "core:fmt"
import "core:os"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

Player :: struct {
	sprite:   Sprite,
	position: Vec2,
	velocity: Vec2,
}

create_player :: proc(game: ^Game) -> (player: Player) {
	TEXTURE_PATH :: "assets/sprites/cat.png"

	texture := SDL_Image.LoadTexture(game.renderer, TEXTURE_PATH)
	if texture == nil {
		fmt.eprintln("ERROR: Failed to load the player texture: %s", SDL.GetErrorString())
		os.exit(1)
	}

	player.position = Vec2{20.0, f32(game.window_height) / 2 - 100}
	player.velocity = Vec2{0.0, -100.0}
	player.sprite.texture = texture

	horizontal_padding: i32 = 7
	vertical_padding: i32 = 16

	horizontal_size: i32 = 16
	vertical_size: i32 = 16


	// TODO: adjust the source over time to animate the sprite
	player.sprite.source = SDL.Rect {
		x = horizontal_padding,
		y = vertical_padding,
		w = horizontal_size,
		h = vertical_size,
	}

	// TODO: reduce the destination size to make the cat smaller later
	player.sprite.destination = SDL.Rect {
		x = 0,
		y = 0,
		w = 200,
		h = 200,
	}

	// TODO: adapt sprite position to be relative to parent
	player.sprite.position = player.position

	return player
}
