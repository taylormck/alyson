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

EntityId :: enum {
	Player,
	Title,
	SubTitle,
}

Entity :: struct {
	destination: SDL.Rect,
	source:      SDL.Rect,
	texture:     ^SDL.Texture,
	position:    [2]f32,
}

InputEventId :: enum {
	move_left,
	move_right,
}

InputEvent :: struct {
	is_pressed:      bool,
	is_just_pressed: bool,
	value:           f32,
}

Input :: struct {
	events: [InputEventId]InputEvent,
}

Game :: struct {
	window:        ^SDL.Window,
	window_width:  i32,
	window_height: i32,
	renderer:      ^SDL.Renderer,
	font:          ^SDL_TTF.Font,
	font_size:     i32,

	// TODO: Should maybe separate in-game entities and UI entities
	entities:      [EntityId]Entity,
	input:         Input,
}

game := Game {
	window_width  = 1920,
	window_height = 1080,
	font_size     = 28,
}


main :: proc() {
	init_sdl()
	defer clean_sdl()

	create_text_entities()
	create_player_entity()

	event: SDL.Event

	prev_tick := time.tick_now()
	counter: f32 = 0

	game_loop: for {
		for SDL.PollEvent(&event) {
			if end_game(&event) {
				break game_loop
			}

			handle_events(&event)
		}

		// Update our clock
		new_tick := time.tick_now()
		duration := time.tick_diff(prev_tick, new_tick)
		prev_tick = new_tick
		delta := f32(time.duration_seconds(duration))

		counter += delta

		// New keyboard events are handled above along with other events.
		// However, this checks the current state of input devices, including
		// reporting which keyboard buttons are being held.
		check_input()

		update_scene(delta)
		draw_scene()

		reset_input()
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

	#partial switch event.key.keysym.scancode {
	case .LEFT:
		game.input.events[InputEventId.move_left].is_just_pressed = true
	case .RIGHT:
		game.input.events[InputEventId.move_right].is_just_pressed = true
	}
}

check_input :: proc() {
	keyboard_state := SDL.GetKeyboardState(nil)
	// NOTE: Is there a better way than just checking every action one-by-one ?
	// TODO: Make the inputs configurable. That means saving the input config to file,
	// then loading it when initializing the game. Finally, we'll need to add a menu
	// so that users can configure it.
	game.input.events[InputEventId.move_left].is_pressed =
		keyboard_state[SDL.SCANCODE_LEFT] != 0 || keyboard_state[SDL.SCANCODE_A] != 0

	// TODO: adjust for gamepad analog controls
	if game.input.events[InputEventId.move_left].is_pressed {
		game.input.events[InputEventId.move_left].value = 1
	} else {
		game.input.events[InputEventId.move_left].value = 0
	}

	game.input.events[InputEventId.move_right].is_pressed =
		keyboard_state[SDL.SCANCODE_RIGHT] != 0 || keyboard_state[SDL.SCANCODE_D] != 0


	// TODO: adjust for gamepad analog controls
	if game.input.events[InputEventId.move_right].is_pressed {
		game.input.events[InputEventId.move_right].value = 1
	} else {
		game.input.events[InputEventId.move_right].value = 0
	}
}

reset_input :: proc() {
	game.input.events[InputEventId.move_left].is_just_pressed = false
	game.input.events[InputEventId.move_right].is_just_pressed = false
}

get_axis :: proc(left: f32, right: f32) -> f32 {
	return right - left
}

update_scene :: proc(delta: f32) {
	player_speed :: 300.0

	player_horizontal_movement_input := get_axis(
		game.input.events[.move_left].value,
		game.input.events[.move_right].value,
	)

	game.entities[EntityId.Player].position.x +=
		player_horizontal_movement_input * player_speed * delta

	game.entities[EntityId.Player].destination.x = i32(game.entities[EntityId.Player].position.x)
}

draw_scene :: proc() {
	SDL.RenderPresent(game.renderer)
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
	SDL.RenderClear(game.renderer)

	for &entity in game.entities {
		SDL.RenderCopy(game.renderer, entity.texture, &entity.source, &entity.destination)
	}
}

create_text :: proc(str: cstring, scale: i32 = 1) -> Entity {
	surface := SDL_TTF.RenderText_Solid(game.font, str, COLOR_WHITE)
	defer SDL.FreeSurface(surface)

	texture := SDL.CreateTextureFromSurface(game.renderer, surface)

	dest_rect := SDL.Rect{}
	SDL_TTF.SizeText(game.font, str, &dest_rect.w, &dest_rect.h)

	dest_rect.w *= scale
	dest_rect.h *= scale

	// We return destination and source rects that match here.
	// The caller should feel free to edit the destination rect, but leave
	// the source rect alone.
	return Entity{texture = texture, destination = dest_rect, source = dest_rect}
}

create_text_entities :: proc() {
	title := create_text("Testing", 3)
	title.destination.x = game.window_width / 2 - title.destination.w / 2
	title.destination.y = game.window_height / 2 - title.destination.h

	sub_title := create_text("One, Two, Three")
	sub_title.destination.x = game.window_width / 2 - sub_title.destination.w / 2
	sub_title.destination.y = game.window_height / 2 - sub_title.destination.h

	game.entities[EntityId.Title] = title
	game.entities[EntityId.SubTitle] = sub_title
}

create_player_entity :: proc() {
	TEXTURE_PATH :: "assets/sprites/cat.png"

	texture := SDL_Image.LoadTexture(game.renderer, TEXTURE_PATH)
	if texture == nil {
		fmt.eprintln("ERROR: Failed to load the player texture: %s", SDL.GetErrorString())
		os.exit(1)
	}

	position := [2]f32{20.0, f32(game.window_width) / 2.0}

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
		position    = position,
	}
}

end_game :: proc(event: ^SDL.Event) -> (exit: bool) {
	return event.type == SDL.EventType.QUIT || event.key.keysym.scancode == .ESCAPE
}
