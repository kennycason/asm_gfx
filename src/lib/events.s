// ============================================================================
// events.s - Window event handling
// ============================================================================
// Handles window-level events (close button, etc.)
//
// Functions:
//   events_poll       - Poll for window events
//   events_should_quit - Check if quit was requested
// ============================================================================

.global _events_poll
.global _events_should_quit

.include "include/constants.inc"

.text

// ============================================================================
// _events_poll - Poll and process window events
// Input:  none
// Output: none
// ============================================================================
.align 4
_events_poll:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #64              // Space for SDL_Event (56 bytes, aligned)
    
poll_loop:
    mov     x0, sp
    bl      _SDL_PollEvent
    cbz     w0, poll_done            // No more events
    
    // Check event type
    ldr     w1, [sp]                 // event.type
    
    // Check for window close (SDL_QUIT)
    mov     w2, #SDL_QUIT
    cmp     w1, w2
    b.ne    poll_loop
    
    // Set quit flag
    adrp    x2, quit_flag@PAGE
    add     x2, x2, quit_flag@PAGEOFF
    mov     w3, #1
    str     w3, [x2]
    b       poll_loop
    
poll_done:
    add     sp, sp, #64
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _events_should_quit - Check if quit was requested
// Input:  none
// Output: w0 = 1 if should quit, 0 otherwise
// ============================================================================
.align 4
_events_should_quit:
    adrp    x0, quit_flag@PAGE
    add     x0, x0, quit_flag@PAGEOFF
    ldr     w0, [x0]
    ret

// ============================================================================
// Data section
// ============================================================================
.data
.align 4
quit_flag:      .word 0

