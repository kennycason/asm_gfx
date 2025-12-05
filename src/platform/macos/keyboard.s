// ============================================================================
// keyboard.s - Native macOS keyboard handling
// ============================================================================
// Uses CoreGraphics CGEventSourceKeyState to query keyboard.
//
// Functions:
//   keyboard_update      - Update key states (call once per frame)
//   keyboard_get_state   - Get pointer to current key state array
//   keyboard_is_held     - Check if key is currently held
//   keyboard_just_pressed - Check if key was just pressed this frame
// ============================================================================

.global _keyboard_update
.global _keyboard_get_state
.global _keyboard_is_held
.global _keyboard_just_pressed
.global _keyboard_is_pressed
.global _native_key_state

.include "include/constants.inc"

.text

// ============================================================================
// Mac Virtual Key Codes
// ============================================================================
.set kVK_ANSI_A,            0x00
.set kVK_ANSI_S,            0x01
.set kVK_ANSI_D,            0x02
.set kVK_ANSI_W,            0x0D
.set kVK_ANSI_Q,            0x0C
.set kVK_Space,             0x31
.set kVK_Escape,            0x35
.set kVK_LeftArrow,         0x7B
.set kVK_RightArrow,        0x7C
.set kVK_DownArrow,         0x7D
.set kVK_UpArrow,           0x7E

.set kCGEventSourceStateCombinedSessionState, 0

// ============================================================================
// _keyboard_is_pressed - Check if a specific key is pressed (raw)
// Input:  w0 = Mac virtual key code
// Output: w0 = 1 if pressed, 0 if not
// ============================================================================
.align 4
_keyboard_is_pressed:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    mov     w1, w0
    mov     w0, #kCGEventSourceStateCombinedSessionState
    bl      _CGEventSourceKeyState
    and     w0, w0, #1
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _keyboard_update - Update key states
// Copies current state to previous, then reads new current state
// ============================================================================
.align 4
_keyboard_update:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    // Get pointers
    adrp    x19, _native_key_state@PAGE
    add     x19, x19, _native_key_state@PAGEOFF
    adrp    x20, _prev_key_state@PAGE
    add     x20, x20, _prev_key_state@PAGEOFF
    
    // Copy current -> previous (16 bytes)
    ldr     x0, [x19]
    str     x0, [x20]
    ldr     x0, [x19, #8]
    str     x0, [x20, #8]
    
    // Now read new current state
    
    // Up Arrow
    mov     w0, #kVK_UpArrow
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_UP]
    
    // Down Arrow
    mov     w0, #kVK_DownArrow
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_DOWN]
    
    // Left Arrow
    mov     w0, #kVK_LeftArrow
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_LEFT]
    
    // Right Arrow
    mov     w0, #kVK_RightArrow
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_RIGHT]
    
    // Escape
    mov     w0, #kVK_Escape
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_ESCAPE]
    
    // Space
    mov     w0, #kVK_Space
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_SPACE]
    
    // W
    mov     w0, #kVK_ANSI_W
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_W]
    
    // A
    mov     w0, #kVK_ANSI_A
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_A]
    
    // S
    mov     w0, #kVK_ANSI_S
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_S]
    
    // D
    mov     w0, #kVK_ANSI_D
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_D]
    
    // Q
    mov     w0, #kVK_ANSI_Q
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_Q]
    
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _keyboard_get_state - Get pointer to current key state array
// Output: x0 = pointer to key state array
// ============================================================================
.align 4
_keyboard_get_state:
    adrp    x0, _native_key_state@PAGE
    add     x0, x0, _native_key_state@PAGEOFF
    ret

// ============================================================================
// _keyboard_is_held - Check if a key is currently held (same as get_state)
// Input:  w0 = key index (KEY_UP, etc.)
// Output: w0 = 1 if held, 0 if not
// ============================================================================
.align 4
_keyboard_is_held:
    adrp    x1, _native_key_state@PAGE
    add     x1, x1, _native_key_state@PAGEOFF
    ldrb    w0, [x1, x0]
    ret

// ============================================================================
// _keyboard_just_pressed - Check if key was JUST pressed this frame
// Returns true only on the first frame the key is down
// Input:  w0 = key index (KEY_UP, etc.)
// Output: w0 = 1 if just pressed, 0 otherwise
// ============================================================================
.align 4
_keyboard_just_pressed:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Get current state
    adrp    x1, _native_key_state@PAGE
    add     x1, x1, _native_key_state@PAGEOFF
    ldrb    w2, [x1, x0]             // current[key]
    
    // Get previous state
    adrp    x1, _prev_key_state@PAGE
    add     x1, x1, _prev_key_state@PAGEOFF
    ldrb    w3, [x1, x0]             // prev[key]
    
    // Just pressed = current && !prev
    mvn     w3, w3                   // !prev
    and     w0, w2, w3               // current & !prev
    and     w0, w0, #1               // ensure 0 or 1
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// Key indices
// ============================================================================
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
.set KEY_COUNT,     11

.global KEY_UP
.global KEY_DOWN
.global KEY_LEFT
.global KEY_RIGHT
.global KEY_ESCAPE
.global KEY_SPACE
.global KEY_W
.global KEY_A
.global KEY_S
.global KEY_D
.global KEY_Q

// ============================================================================
// Data
// ============================================================================
.data
.align 4
_native_key_state:  .space 16        // Current key state
_prev_key_state:    .space 16        // Previous frame key state
