package main

import SDL "vendor:sdl2"

// NOTE: as of the time of writing, the order of the enum
// determines the draw order. We should eventually switch to
// something a bit more sane, eventually.
SpriteId :: enum {
    SubTitle,
    Player,
    Title,
}

Sprite :: struct {
    destination: SDL.Rect,
    source:      SDL.Rect,
    texture:     ^SDL.Texture,
    position:    Vec2,
}
