// ============================================================================
// constants.inc - Shared constants for the graphics library
// ============================================================================

// Window settings
.set WINDOW_WIDTH,      800
.set WINDOW_HEIGHT,     600
.set WINDOW_TITLE,      0           // Set at runtime

// Colors (RGBA format for SDL)
.set COLOR_BLACK,       0x000000FF
.set COLOR_WHITE,       0xFFFFFFFF
.set COLOR_RED,         0xFF0000FF
.set COLOR_GREEN,       0x00FF00FF
.set COLOR_BLUE,        0x0000FFFF
.set COLOR_YELLOW,      0xFFFF00FF
.set COLOR_CYAN,        0x00FFFFFF
.set COLOR_MAGENTA,     0xFF00FFFF

// Shape defaults
.set DEFAULT_SQUARE_SIZE,   50
.set MOVE_SPEED,            10

// SDL Constants
.set SDL_INIT_VIDEO,        0x00000020
.set SDL_WINDOW_SHOWN,      0x00000004
.set SDL_QUIT,              0x100
.set SDL_KEYDOWN,           0x300
.set SDL_KEYUP,             0x301

// SDL Scancodes (for arrow keys) - legacy, kept for reference
.set SDL_SCANCODE_RIGHT,    79
.set SDL_SCANCODE_LEFT,     80
.set SDL_SCANCODE_DOWN,     81
.set SDL_SCANCODE_UP,       82
.set SDL_SCANCODE_ESCAPE,   41

// Native keyboard key indices (keyboard.s)
.set KEY_UP,        0
.set KEY_DOWN,      1
.set KEY_LEFT,      2
.set KEY_RIGHT,     3
.set KEY_ESCAPE,    4
.set KEY_SPACE,     5
.set KEY_W,         6
.set KEY_A,         7
.set KEY_S,         8
.set KEY_D,         9
.set KEY_Q,         10

// macOS system call numbers (ARM64)
.set SYS_EXIT,              1
.set SYS_WRITE,             4
.set STDOUT,                1

