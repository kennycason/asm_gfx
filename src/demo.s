// ============================================================================
// demo.s - Demo entry point: Movable square with arrow keys
// ============================================================================
// A simple demo showing:
//   - Window creation
//   - Drawing a colored square
//   - Moving with arrow keys
//   - ESC or window close to quit
// ============================================================================

.global _main

.include "include/constants.inc"

.text

// ============================================================================
// _main - Entry point
// ============================================================================
.align 4
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Print startup message
    adrp    x0, msg_init@PAGE
    add     x0, x0, msg_init@PAGEOFF
    bl      _print_str
    bl      _print_newline
    
    // Initialize graphics
    adrp    x0, window_title@PAGE
    add     x0, x0, window_title@PAGEOFF
    mov     w1, #WINDOW_WIDTH
    mov     w2, #WINDOW_HEIGHT
    bl      _gfx_init
    
    // Check for init failure
    cmp     x0, #0
    b.eq    init_ok
    
    // Print error and exit
    adrp    x0, msg_error@PAGE
    add     x0, x0, msg_error@PAGEOFF
    bl      _print_str
    bl      _print_newline
    mov     w0, #1
    b       exit_program
    
init_ok:
    adrp    x0, msg_ready@PAGE
    add     x0, x0, msg_ready@PAGEOFF
    bl      _print_str
    bl      _print_newline
    
    // Initialize square position (center of window)
    adrp    x0, square_x@PAGE
    add     x0, x0, square_x@PAGEOFF
    mov     w1, #((WINDOW_WIDTH - DEFAULT_SQUARE_SIZE) / 2)
    str     w1, [x0]
    
    adrp    x0, square_y@PAGE
    add     x0, x0, square_y@PAGEOFF
    mov     w1, #((WINDOW_HEIGHT - DEFAULT_SQUARE_SIZE) / 2)
    str     w1, [x0]

// ============================================================================
// Main game loop
// ============================================================================
game_loop:
    // Poll input events
    bl      _input_poll
    
    // Check if should quit
    bl      _input_should_quit
    cbnz    w0, quit_game
    
    // Handle movement
    bl      handle_movement
    
    // Clear screen (dark blue background)
    mov     w0, #25                  // R
    mov     w1, #25                  // G
    mov     w2, #45                  // B
    mov     w3, #255                 // A
    bl      _gfx_set_color
    bl      _gfx_clear
    
    // Draw the square (bright cyan)
    mov     w0, #0                   // R
    mov     w1, #255                 // G
    mov     w2, #220                 // B
    mov     w3, #255                 // A
    bl      _gfx_set_color
    
    // Load square position
    adrp    x0, square_x@PAGE
    add     x0, x0, square_x@PAGEOFF
    ldr     w0, [x0]
    adrp    x1, square_y@PAGE
    add     x1, x1, square_y@PAGEOFF
    ldr     w1, [x1]
    mov     w2, #DEFAULT_SQUARE_SIZE
    mov     w3, #DEFAULT_SQUARE_SIZE
    bl      _draw_rect
    
    // Draw outline (white)
    mov     w0, #255                 // R
    mov     w1, #255                 // G
    mov     w2, #255                 // B
    mov     w3, #255                 // A
    bl      _gfx_set_color
    
    adrp    x0, square_x@PAGE
    add     x0, x0, square_x@PAGEOFF
    ldr     w0, [x0]
    adrp    x1, square_y@PAGE
    add     x1, x1, square_y@PAGEOFF
    ldr     w1, [x1]
    mov     w2, #DEFAULT_SQUARE_SIZE
    mov     w3, #DEFAULT_SQUARE_SIZE
    bl      _draw_rect_outline
    
    // Present frame
    bl      _gfx_present
    
    // Small delay to avoid busy loop (SDL vsync should handle this)
    mov     w0, #16                  // ~60 FPS
    bl      _SDL_Delay
    
    b       game_loop

quit_game:
    adrp    x0, msg_quit@PAGE
    add     x0, x0, msg_quit@PAGEOFF
    bl      _print_str
    bl      _print_newline
    
    // Cleanup
    bl      _gfx_quit
    
    mov     w0, #0                   // Success exit code
    
exit_program:
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// handle_movement - Check key states and update position
// ============================================================================
.align 4
handle_movement:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    
    // Load current position
    adrp    x19, square_x@PAGE
    add     x19, x19, square_x@PAGEOFF
    ldr     w0, [x19]
    
    adrp    x20, square_y@PAGE
    add     x20, x20, square_y@PAGEOFF
    ldr     w1, [x20]
    
    // Get key state array
    adrp    x2, _input_key_state@PAGE
    add     x2, x2, _input_key_state@PAGEOFF
    
    // Check LEFT arrow
    ldrb    w3, [x2, #SDL_SCANCODE_LEFT]
    cbz     w3, check_right
    sub     w0, w0, #MOVE_SPEED
    cmp     w0, #0
    csel    w0, wzr, w0, lt          // Clamp to 0
    
check_right:
    ldrb    w3, [x2, #SDL_SCANCODE_RIGHT]
    cbz     w3, check_up
    add     w0, w0, #MOVE_SPEED
    mov     w4, #(WINDOW_WIDTH - DEFAULT_SQUARE_SIZE)
    cmp     w0, w4
    csel    w0, w4, w0, gt           // Clamp to max
    
check_up:
    ldrb    w3, [x2, #SDL_SCANCODE_UP]
    cbz     w3, check_down
    sub     w1, w1, #MOVE_SPEED
    cmp     w1, #0
    csel    w1, wzr, w1, lt          // Clamp to 0
    
check_down:
    ldrb    w3, [x2, #SDL_SCANCODE_DOWN]
    cbz     w3, movement_done
    add     w1, w1, #MOVE_SPEED
    mov     w4, #(WINDOW_HEIGHT - DEFAULT_SQUARE_SIZE)
    cmp     w1, w4
    csel    w1, w4, w1, gt           // Clamp to max
    
movement_done:
    // Store updated position
    str     w0, [x19]
    str     w1, [x20]
    
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// Data section
// ============================================================================
.data
.align 4
square_x:       .word 0
square_y:       .word 0

window_title:   .asciz "ASM Graphics Demo"
msg_init:       .asciz "[INFO] Initializing graphics system..."
msg_ready:      .asciz "[INFO] Ready! Use arrow keys to move, ESC to quit."
msg_error:      .asciz "[ERROR] Failed to initialize graphics!"
msg_quit:       .asciz "[INFO] Shutting down..."

