package main

import "core:fmt"
import "core:os"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

// TODO: Read this from a data file
MAX_PLAYER_SPEED :: 300.0
MAX_PLAYER_JUMP_HEIGHT :: 150.0
MAX_PLAYER_JUMP_DISTANCE :: 100.0

INITIAL_JUMP_VELOCITY ::
    (2 * MAX_PLAYER_JUMP_HEIGHT * MAX_PLAYER_SPEED) / MAX_PLAYER_JUMP_DISTANCE
PLAYER_GRAVITY ::
    (2 * MAX_PLAYER_JUMP_HEIGHT * MAX_PLAYER_SPEED * MAX_PLAYER_SPEED) /
    (MAX_PLAYER_JUMP_DISTANCE * MAX_PLAYER_JUMP_DISTANCE)

JUMP_QUEUE_TIMEOUT :: 0.1

Player :: struct {
    sprite:            Sprite,
    position:          Vec2,
    velocity:          Vec2,
    jump_queued_time:  f32,
    current_animation: Animation,
    animation_time:    f32,
}

Animation :: enum {
    Idle,
}

AnimationFrame :: struct {
    duration:   f32,
    dimensions: SDL.Rect,
}

animation_frames := [Animation][]AnimationFrame {
    .Idle = {
        {duration = 1.0, dimensions = SDL.Rect{x = 7, y = 16, w = 16, h = 16}},
        {
            duration = 1.0,
            dimensions = SDL.Rect{x = 39, y = 16, w = 16, h = 16},
        },
        {
            duration = 1.0,
            dimensions = SDL.Rect{x = 72, y = 16, w = 16, h = 16},
        },
        {
            duration = 1.0,
            dimensions = SDL.Rect{x = 39, y = 16, w = 16, h = 16},
        },
    },
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
    player.current_animation = .Idle

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

/*
 * v0 = jump force || initial jump vertical velocity
 * g = gravity
 *
 * h = maximum jump height
 * xh = maximum jump distance
 * vx = maximum vertical velocity
 */

update_player :: proc(player: ^Player, game: ^Game, delta: f32) {
    // TODO: move these out to constant
    max_gravity :: 1_000.0
    falling_gravity_multiplier :: 3.0

    // TODO: replace this with collisions
    bottom := f32(game.window_height - player.sprite.destination.h)

    player_horizontal_movement_input := get_axis(
        game.input.events[.move_left].value,
        game.input.events[.move_right].value,
    )

    // TODO: add movement acceleration
    player.velocity.x = player_horizontal_movement_input * MAX_PLAYER_SPEED
    player.position.x += player.velocity.x * delta

    player.position.x = clamp(
        player.position.x,
        0,
        f32(game.window_width - player.sprite.destination.w),
    )

    if player.position.y < bottom {
        gravity_multiplier: f32 = 1.0

        // Increase gravity while falling.
        // This can happen either after the player reaches the peak of
        // their jump, or after they let go of the jump button.
        if player.velocity.y > 0 || !game.input.events[.jump].is_pressed {
            gravity_multiplier = falling_gravity_multiplier
        } else if player.velocity.y < -5 {
            // Decrease gravity at the top of the jump to give players
            // a bit of hang time.
            gravity_multiplier = 0.75
        }

        // Improved approximation of acceleration due to gravity
        acceleration := PLAYER_GRAVITY * gravity_multiplier * delta * 0.5
        player.velocity.y = min(player.velocity.y + acceleration, max_gravity)
        player.position.y = min(
            player.position.y + player.velocity.y * delta,
            bottom,
        )
        player.velocity.y = min(player.velocity.y + acceleration, max_gravity)

        if game.input.events[.jump].is_just_pressed {
            player.jump_queued_time = JUMP_QUEUE_TIMEOUT
        } else if player.jump_queued_time > 0 {
            player.jump_queued_time = player.jump_queued_time - delta
        }
    } else if game.input.events[.jump].is_just_pressed ||
       player.jump_queued_time > 0 {
        player.velocity.y = -INITIAL_JUMP_VELOCITY
        player.position.y -= INITIAL_JUMP_VELOCITY * delta
    } else {
        player.velocity.y = 0
        player.position.y = bottom
    }

    player.animation_time += delta
    remaining_time := player.animation_time
    current_frame_index := 0
    current_animation_frames := animation_frames[player.current_animation]
    current_animation_duration: f32 = 0

    for remaining_time > 0 {
        duration := current_animation_frames[current_frame_index].duration
        remaining_time -= duration
        current_animation_duration += duration
        current_frame_index += 1

        if current_frame_index >= len(&current_animation_frames) {
            player.animation_time -= current_animation_duration
            current_animation_duration = 0
            current_frame_index = 0
        }
    }

    player.sprite.source =
        current_animation_frames[current_frame_index].dimensions

    // TODO: refactor so that we don't have to set this twice
    game.sprites[SpriteId.Player].source = player.sprite.source

    // TODO: make sprite render relative to the position
    game.sprites[SpriteId.Player].destination.x = i32(game.player.position.x)
    game.sprites[SpriteId.Player].destination.y = i32(game.player.position.y)
}
