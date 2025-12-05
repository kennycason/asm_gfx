// ============================================================================
// keyboard.s - Native macOS keyboard handling (no SDL!)
// ============================================================================
// Uses CoreGraphics CGEventSourceKeyState to directly query keyboard.
// No dependency on SDL event loop for key state!
//
// Functions:
//   keyboard_is_pressed  - Check if a key is currently pressed
//   keyboard_update      - Update internal key state cache
//   keyboard_get_state   - Get pointer to key state array
// ============================================================================

.global _keyboard_is_pressed
.global _keyboard_update
.global _keyboard_get_state
.global _native_key_state

.include "include/constants.inc"

.text

// ============================================================================
// Mac Virtual Key Codes (different from SDL scancodes!)
// ============================================================================
.set kVK_ANSI_A,            0x00
.set kVK_ANSI_S,            0x01
.set kVK_ANSI_D,            0x02
.set kVK_ANSI_F,            0x03
.set kVK_ANSI_W,            0x0D
.set kVK_ANSI_Q,            0x0C
.set kVK_Space,             0x31
.set kVK_Escape,            0x35
.set kVK_LeftArrow,         0x7B
.set kVK_RightArrow,        0x7C
.set kVK_DownArrow,         0x7D
.set kVK_UpArrow,           0x7E

// CGEventSourceStateID
.set kCGEventSourceStateCombinedSessionState, 0

// ============================================================================
// _keyboard_is_pressed - Check if a specific key is pressed
// Input:  w0 = Mac virtual key code
// Output: w0 = 1 if pressed, 0 if not
// ============================================================================
.align 4
_keyboard_is_pressed:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // CGEventSourceKeyState(kCGEventSourceStateCombinedSessionState, keyCode)
    mov     w1, w0                   // key code -> second arg
    mov     w0, #kCGEventSourceStateCombinedSessionState
    bl      _CGEventSourceKeyState
    
    // Result is already in w0 (bool)
    and     w0, w0, #1               // Ensure 0 or 1
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _keyboard_update - Update internal key state array
// Polls all relevant keys and caches their state
// Input:  none
// Output: none
// ============================================================================
.align 4
_keyboard_update:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    
    // Get pointer to our key state array
    adrp    x19, _native_key_state@PAGE
    add     x19, x19, _native_key_state@PAGEOFF
    
    // Check Up Arrow
    mov     w0, #kVK_UpArrow
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_UP]
    
    // Check Down Arrow
    mov     w0, #kVK_DownArrow
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_DOWN]
    
    // Check Left Arrow
    mov     w0, #kVK_LeftArrow
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_LEFT]
    
    // Check Right Arrow
    mov     w0, #kVK_RightArrow
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_RIGHT]
    
    // Check Escape
    mov     w0, #kVK_Escape
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_ESCAPE]
    
    // Check Space
    mov     w0, #kVK_Space
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_SPACE]
    
    // Check W
    mov     w0, #kVK_ANSI_W
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_W]
    
    // Check A
    mov     w0, #kVK_ANSI_A
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_A]
    
    // Check S
    mov     w0, #kVK_ANSI_S
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_S]
    
    // Check D
    mov     w0, #kVK_ANSI_D
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_D]
    
    // Check Q (for quit)
    mov     w0, #kVK_ANSI_Q
    bl      _keyboard_is_pressed
    strb    w0, [x19, #KEY_Q]
    
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _keyboard_get_state - Get pointer to key state array
// Input:  none
// Output: x0 = pointer to key state array
// ============================================================================
.align 4
_keyboard_get_state:
    adrp    x0, _native_key_state@PAGE
    add     x0, x0, _native_key_state@PAGEOFF
    ret

// ============================================================================
// Key indices in our state array (simple enum)
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

// Export key indices for use by other modules
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
// Data section
// ============================================================================
.data
.align 4
_native_key_state:  .space 16        // Key state array (one byte per key)

