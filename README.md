# ASM Graphics Library

![Screenshot](screenshot.png)

A minimal graphics library written in ARM64 assembly for macOS using native system frameworks.

## Features

- **Software Rasterizer**: Custom framebuffer with pixel-level drawing
- **Classic Algorithms**: Bresenham's line, midpoint circle
- **Native Window**: Cocoa window via Objective-C runtime
- **Native Keyboard**: Direct input via CoreGraphics
- **Native Timing**: System nanosleep for frame timing
- **Console Output**: Strings, integers, hex via syscalls

## Project Structure

```
asm_gfx/
├── include/
│   └── constants.inc         # Shared constants
├── src/
│   ├── shared/
│   │   └── raster.s          # Software rasterizer (portable)
│   ├── platform/
│   │   └── macos/
│   │       ├── print.s       # Console output (syscalls)
│   │       ├── keyboard.s    # Keyboard input (CoreGraphics)
│   │       ├── window.s      # Window management (Cocoa)
│   │       └── timing.s      # Sleep/timing (nanosleep)
│   └── demo.s                # Demo application
├── build/                    # Build output
├── Makefile
└── README.md
```

## Requirements

- macOS (Apple Silicon)
- Xcode Command Line Tools

## Quick Start

### Build

```bash
make
```

### Run

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

### Print Module (`platform/macos/print.s`)

```asm
// Print a null-terminated string
adrp    x0, my_string@PAGE
add     x0, x0, my_string@PAGEOFF
bl      _print_str
bl      _print_newline

// Print integer
mov     x0, #42
bl      _print_int

// Print hex
mov     x0, #0xDEADBEEF
bl      _print_hex
```

### Window Module (`platform/macos/window.s`)

```asm
// Initialize window (title, width, height)
adrp    x0, title@PAGE
add     x0, x0, title@PAGEOFF
mov     w1, #800
mov     w2, #600
bl      _window_init

// Poll events (call each frame)
bl      _window_poll

// Check if window should close
bl      _window_should_close
cbnz    w0, exit_loop

// Blit framebuffer to window (buffer, width, height, pitch)
mov     x0, buffer_ptr
mov     w1, #800
mov     w2, #600
mov     w3, pitch
bl      _window_blit

// Cleanup
bl      _window_quit
```

### Keyboard Module (`platform/macos/keyboard.s`)

```asm
// Update key states (call each frame)
bl      _keyboard_update

// Get pointer to key state array
bl      _keyboard_get_state
mov     x2, x0

// Check keys using KEY_* constants
ldrb    w0, [x2, #KEY_UP]
cbnz    w0, handle_up

// Available: KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT
//            KEY_ESCAPE, KEY_SPACE
//            KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q

// Or check by Mac virtual keycode
mov     w0, #0x7E              // kVK_UpArrow
bl      _keyboard_is_pressed
```

### Timing Module (`platform/macos/timing.s`)

```asm
// Sleep for milliseconds
mov     w0, #16                // ~60 FPS
bl      _timing_sleep_ms

// Sleep for microseconds
mov     w0, #16000
bl      _timing_sleep_us
```

### Raster Module (`shared/raster.s`)

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

// Clear framebuffer
bl      _raster_clear

// Plot pixel (x, y)
mov     w0, #100
mov     w1, #200
bl      _raster_plot

// Draw line (x0, y0, x1, y1)
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

// Draw circle outline (cx, cy, radius)
mov     w0, #400
mov     w1, #300
mov     w2, #100
bl      _raster_circle

// Draw filled circle
bl      _raster_circle_filled

// Get framebuffer pointer
bl      _raster_get_buffer

// Free framebuffer
bl      _raster_free
```

## Adding Linux Support

The project is structured for cross-platform support. To add Linux:

1. Create `src/platform/linux/` directory
2. Implement platform modules:
   - `print.s` - Use Linux syscall numbers
   - `keyboard.s` - Use X11 or evdev
   - `window.s` - Use X11 or Wayland
   - `timing.s` - Use Linux nanosleep
3. Update Makefile with Linux target

The `shared/raster.s` module is portable and needs no changes.

## Architecture Notes

ARM64 (Apple Silicon) calling convention:
- Arguments: x0-x7 (w0-w7 for 32-bit)
- Return value: x0
- Callee-saved: x19-x28
- Frame pointer: x29
- Link register: x30
- Stack: 16-byte aligned

## License

MIT
