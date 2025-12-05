// ============================================================================
// constants.inc - Shared constants for the graphics library
// ============================================================================

// Window settings
.set WINDOW_WIDTH,      800
.set WINDOW_HEIGHT,     600

// Shape defaults
.set DEFAULT_SQUARE_SIZE,   50
.set MOVE_SPEED,            10

// Colors (ARGB format)
.set COLOR_BLACK,       0xFF000000
.set COLOR_WHITE,       0xFFFFFFFF
.set COLOR_RED,         0xFFFF0000
.set COLOR_GREEN,       0xFF00FF00
.set COLOR_BLUE,        0xFF0000FF
.set COLOR_YELLOW,      0xFFFFFF00
.set COLOR_CYAN,        0xFF00FFFF
.set COLOR_MAGENTA,     0xFFFF00FF

// Keyboard key indices (keyboard.s)
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

// SDL event types (events.s)
.set SDL_INIT_VIDEO,        0x00000020
.set SDL_WINDOW_SHOWN,      0x00000004
.set SDL_QUIT,              0x100

// macOS system calls (ARM64)
.set SYS_EXIT,              1
.set SYS_WRITE,             4
.set STDOUT,                1
