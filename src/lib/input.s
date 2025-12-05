// ============================================================================
// input.s - Keyboard input handling
// ============================================================================
// Functions:
//   input_poll     - Poll for input events
//   input_get_key  - Get the last key pressed
//   input_should_quit - Check if quit was requested
// ============================================================================

.global _input_poll
.global _input_get_key
.global _input_should_quit
.global _input_key_state

.include "include/constants.inc"

.text

// ============================================================================
// _input_poll - Poll and process all pending events
// Input:  none
// Output: none
// Updates internal state for key presses and quit flag
// ============================================================================
.align 4
_input_poll:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #64              // Allocate space for SDL_Event (56 bytes, aligned)
    
poll_loop:
    // SDL_PollEvent(&event)
    mov     x0, sp
    bl      _SDL_PollEvent
    cbz     w0, poll_done            // No more events
    
    // Check event type (first 4 bytes of SDL_Event)
    ldr     w1, [sp]                 // event.type
    
    // Check for SDL_QUIT
    mov     w2, #SDL_QUIT
    cmp     w1, w2
    b.ne    check_keydown
    
    // Set quit flag
    adrp    x2, quit_flag@PAGE
    add     x2, x2, quit_flag@PAGEOFF
    mov     w3, #1
    str     w3, [x2]
    b       poll_loop
    
check_keydown:
    // Check for SDL_KEYDOWN
    mov     w2, #SDL_KEYDOWN
    cmp     w1, w2
    b.ne    check_keyup
    
    // Get scancode (offset 16 in SDL_KeyboardEvent)
    ldr     w1, [sp, #16]            // keysym.scancode
    
    // Store last key
    adrp    x2, last_key@PAGE
    add     x2, x2, last_key@PAGEOFF
    str     w1, [x2]
    
    // Update key state array
    adrp    x2, _input_key_state@PAGE
    add     x2, x2, _input_key_state@PAGEOFF
    cmp     w1, #512                 // Bounds check
    b.ge    poll_loop
    mov     w3, #1
    strb    w3, [x2, x1]             // key_state[scancode] = 1
    
    // Check for ESC key -> quit
    cmp     w1, #SDL_SCANCODE_ESCAPE
    b.ne    poll_loop
    adrp    x2, quit_flag@PAGE
    add     x2, x2, quit_flag@PAGEOFF
    mov     w3, #1
    str     w3, [x2]
    b       poll_loop
    
check_keyup:
    // Check for SDL_KEYUP
    mov     w2, #SDL_KEYUP
    cmp     w1, w2
    b.ne    poll_loop
    
    // Get scancode
    ldr     w1, [sp, #16]            // keysym.scancode
    
    // Update key state array
    adrp    x2, _input_key_state@PAGE
    add     x2, x2, _input_key_state@PAGEOFF
    cmp     w1, #512                 // Bounds check
    b.ge    poll_loop
    mov     w3, #0
    strb    w3, [x2, x1]             // key_state[scancode] = 0
    
    b       poll_loop
    
poll_done:
    add     sp, sp, #64
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _input_get_key - Get the last key pressed (scancode)
// Input:  none
// Output: w0 = scancode of last key, or 0 if none
// ============================================================================
.align 4
_input_get_key:
    adrp    x0, last_key@PAGE
    add     x0, x0, last_key@PAGEOFF
    ldr     w0, [x0]
    ret

// ============================================================================
// _input_should_quit - Check if quit was requested
// Input:  none
// Output: w0 = 1 if should quit, 0 otherwise
// ============================================================================
.align 4
_input_should_quit:
    adrp    x0, quit_flag@PAGE
    add     x0, x0, quit_flag@PAGEOFF
    ldr     w0, [x0]
    ret

// ============================================================================
// Data section
// ============================================================================
.data
.align 4
last_key:       .word 0
quit_flag:      .word 0

.bss
.align 4
_input_key_state:  .space 512        // Key state array (one byte per scancode)

