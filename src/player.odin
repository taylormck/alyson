package main

import "core:fmt"
import "core:os"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

// TODO: Read this from a data file
max_player_speed :: 300.0

Player :: struct {
    sprite:   Sprite,
    position: Vec2,
    velocity: Vec2,
}

create_player :: proc(game: ^Game) -> (player: Player) {
    TEXTURE_PATH :: "assets/sprites/cat.png"

    texture := SDL_Image.LoadTexture(game.renderer, TEXTURE_PATH)
    if texture == nil {
        fmt.eprintln(
            "ERROR: Failed to load the player texture: %s",
            SDL.GetErrorString(),
        )
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
        w = 50,
        h = 50,
    }

    // TODO: adapt sprite position to be relative to parent
    player.sprite.position = player.position

    return player
}

update_player :: proc(player: ^Player, game: ^Game, delta: f32) {
    // TODO: calculate these based on player's jump height and speed
    gravity :: 1000.0
    jump_power :: 750.0
    falling_gravity_multiplier :: 3.0

    // TODO: replace this with collisions
    bottom := f32(game.window_height - player.sprite.destination.h)

    player_horizontal_movement_input := get_axis(
        game.input.events[.move_left].value,
        game.input.events[.move_right].value,
    )

    player.velocity.x = player_horizontal_movement_input * max_player_speed
    player.position.x += player.velocity.x * delta

    // If the player somehow ends up below the bottom of the screen,
    // go ahead and just move them back up to the bototm of the screen.
    if player.position.y > bottom {
        player.position.y = bottom
    }

    if player.position.y < bottom {
        gravity_multiplier: f32 = 1.0

        // Increase gravity while falling.
        // This can happen either after the player reaches the peak of
        // their jump, or after they let go of the jump button.
        if player.velocity.y > 0 || !game.input.events[.jump].is_pressed {
            gravity_multiplier = falling_gravity_multiplier
        }

        // Improved approximation of acceleration due to gravity
        acceleration := gravity * gravity_multiplier * delta * 0.5
        player.velocity.y += acceleration
        player.position.y = min(
            player.position.y + player.velocity.y * delta,
            bottom,
        )
        player.velocity.y += acceleration
    } else if game.input.events[.jump].is_just_pressed {
        player.velocity.y = -jump_power
        player.position.y -= jump_power * delta
    } else {
        player.velocity.y = 0
    }

    // TODO: make sprite render relative to the position
    game.sprites[SpriteId.Player].destination.x = i32(game.player.position.x)
    game.sprites[SpriteId.Player].destination.y = i32(game.player.position.y)
}
