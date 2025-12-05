// ============================================================================
// constants.inc - Shared constants for Maze ASM
// ============================================================================
// Central configuration for window, colors, keyboard, and system calls.
// ============================================================================

// Window dimensions (41x31 tiles @ 16px each)
.set WINDOW_WIDTH,      656
.set WINDOW_HEIGHT,     496

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
.set KEY_R,         11

// macOS system calls (ARM64)
.set SYS_EXIT,              1
.set SYS_WRITE,             4
.set STDOUT,                1
