# ASM Graphics Library

![Screenshot](screenshot.png)

A minimal graphics library written in ARM64 assembly for macOS, featuring a custom software rasterizer and native keyboard input.

## Features

- **Software Rasterizer**: Custom framebuffer with pixel-level drawing
- **Classic Algorithms**: Bresenham's line, midpoint circle
- **Native Keyboard**: Direct input via CoreGraphics
- **Console Printing**: Strings, integers, hex via syscalls
- **Window Management**: SDL2 for window creation and display

## Project Structure

```
asm_gfx/
├── include/
│   └── constants.inc    # Shared constants
├── src/
│   ├── lib/
│   │   ├── print.s      # Console output
│   │   ├── window.s     # Window management
│   │   ├── events.s     # Window events
│   │   ├── keyboard.s   # Native keyboard input
│   │   └── raster.s     # Software rasterizer
│   └── demo.s           # Demo application
├── build/               # Build output
├── Makefile
└── README.md
```

## Requirements

- macOS (Apple Silicon or Intel)
- Xcode Command Line Tools
- SDL2 library

## Quick Start

### 1. Install SDL2

```bash
make install-sdl
# or manually:
brew install sdl2
```

### 2. Build

```bash
make
```

### 3. Run

```bash
make run
# or directly:
./build/demo
```

## Controls

| Key | Action |
|-----|--------|
| ↑ / W | Move up |
| ↓ / S | Move down |
| ← / A | Move left |
| → / D | Move right |
| ESC / Q | Quit |

## Library API

### Print Module (`print.s`)

```asm
// Print a null-terminated string
adrp    x0, my_string@PAGE
add     x0, x0, my_string@PAGEOFF
bl      _print_str

// Print newline
bl      _print_newline

// Print integer
mov     x0, #42
bl      _print_int

// Print hex
mov     x0, #0xDEADBEEF
bl      _print_hex
```

### Window Module (`window.s`)

```asm
// Initialize window (title, width, height)
adrp    x0, title@PAGE
add     x0, x0, title@PAGEOFF
mov     w1, #800
mov     w2, #600
bl      _gfx_init

// Create texture for framebuffer blitting
mov     w0, #800
mov     w1, #600
bl      _gfx_create_texture

// Blit framebuffer to screen
mov     x0, buffer_ptr
mov     w1, pitch
bl      _gfx_blit

// Cleanup
bl      _gfx_quit
```

### Events Module (`events.s`)

```asm
// Poll window events (call each frame)
bl      _events_poll

// Check if window close was requested
bl      _events_should_quit
cbnz    w0, exit_loop
```

### Keyboard Module (`keyboard.s`)

```asm
// Update key states (call each frame)
bl      _keyboard_update

// Get pointer to key state array
bl      _keyboard_get_state
mov     x2, x0

// Check keys using KEY_* constants
ldrb    w0, [x2, #KEY_UP]
cbnz    w0, handle_up

ldrb    w0, [x2, #KEY_ESCAPE]
cbnz    w0, quit_game

// Available: KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT
//            KEY_ESCAPE, KEY_SPACE
//            KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q

// Or check individual key by Mac virtual keycode
mov     w0, #0x7E              // kVK_UpArrow
bl      _keyboard_is_pressed
cbnz    w0, up_is_pressed
```

### Raster Module (`raster.s`)

```asm
// Initialize framebuffer (width, height)
mov     w0, #800
mov     w1, #600
bl      _raster_init

// Set drawing color (R, G, B, A)
mov     w0, #255
mov     w1, #0
mov     w2, #128
mov     w3, #255
bl      _raster_set_color

// Clear framebuffer with current color
bl      _raster_clear

// Plot single pixel (x, y)
mov     w0, #100
mov     w1, #200
bl      _raster_plot

// Draw line - Bresenham's algorithm (x0, y0, x1, y1)
mov     w0, #0
mov     w1, #0
mov     w2, #400
mov     w3, #300
bl      _raster_line

// Draw filled rectangle (x, y, width, height)
mov     w0, #100
mov     w1, #100
mov     w2, #50
mov     w3, #50
bl      _raster_rect

// Draw rectangle outline
bl      _raster_rect_outline

// Draw circle outline - midpoint algorithm (cx, cy, radius)
mov     w0, #400
mov     w1, #300
mov     w2, #100
bl      _raster_circle

// Draw filled circle
bl      _raster_circle_filled

// Get framebuffer for blitting
bl      _raster_get_buffer   // x0 = buffer ptr

// Free framebuffer on exit
bl      _raster_free
```

## Constants (`constants.inc`)

Key constants available:
- `WINDOW_WIDTH`, `WINDOW_HEIGHT`
- `KEY_UP`, `KEY_DOWN`, `KEY_LEFT`, `KEY_RIGHT`, `KEY_ESCAPE`, etc.
- `MOVE_SPEED`, `DEFAULT_SQUARE_SIZE`

## Extending the Library

### Adding New Shapes

Add functions to `raster.s`:

```asm
.global _raster_triangle

_raster_triangle:
    // Your implementation
    ret
```

### Adding New Demos

Create a new file in `src/`:

```asm
.global _main
.include "include/constants.inc"

_main:
    // Your demo code
    ret
```

Update the Makefile to build your demo.

## Architecture Notes

This library targets ARM64 (Apple Silicon). Key calling convention details:
- Arguments: x0-x7 (w0-w7 for 32-bit)
- Return value: x0
- Callee-saved: x19-x28
- Frame pointer: x29
- Link register: x30
- Stack must be 16-byte aligned

## License

MIT
