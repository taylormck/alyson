package main

import SDL "vendor:sdl2"

EntityId :: enum {
	Player,
	Title,
	SubTitle,
}

Entity :: struct {
	destination: SDL.Rect,
	source:      SDL.Rect,
	texture:     ^SDL.Texture,
	position:    Vec2,
}
