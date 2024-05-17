package main

import SDL "vendor:sdl2"

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

handle_keyboard_event :: proc(input: ^Input, code: SDL.Scancode) {
	#partial switch code {
	case .LEFT:
		input.events[InputEventId.move_left].is_just_pressed = true
	case .RIGHT:
		input.events[InputEventId.move_right].is_just_pressed = true
	}
}

check_input :: proc(input: ^Input) {
	keyboard_state := SDL.GetKeyboardState(nil)
	// NOTE: Is there a better way than just checking every action one-by-one ?
	// TODO: Make the inputs configurable. That means saving the input config to file,
	// then loading it when initializing the game. Finally, we'll need to add a menu
	// so that users can configure it.
	input.events[InputEventId.move_left].is_pressed =
		keyboard_state[SDL.SCANCODE_LEFT] != 0 || keyboard_state[SDL.SCANCODE_A] != 0

	// TODO: adjust for gamepad analog controls
	if input.events[InputEventId.move_left].is_pressed {
		input.events[InputEventId.move_left].value = 1
	} else {
		input.events[InputEventId.move_left].value = 0
	}

	input.events[InputEventId.move_right].is_pressed =
		keyboard_state[SDL.SCANCODE_RIGHT] != 0 || keyboard_state[SDL.SCANCODE_D] != 0


	// TODO: adjust for gamepad analog controls
	if input.events[InputEventId.move_right].is_pressed {
		input.events[InputEventId.move_right].value = 1
	} else {
		input.events[InputEventId.move_right].value = 0
	}
}

reset_input :: proc(input: ^Input) {
	input.events[InputEventId.move_left].is_just_pressed = false
	input.events[InputEventId.move_right].is_just_pressed = false
}

get_axis :: proc(left: f32, right: f32) -> f32 {
	return right - left
}
