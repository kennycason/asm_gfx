// ============================================================================
// demo.s - Demo: Movable square with software rendering
// ============================================================================
// Demonstrates:
//   - Software rasterizer (raster.s)
//   - Native keyboard input (keyboard.s)
//   - Window management (window.s)
//   - Arrow keys / WASD to move, ESC/Q to quit
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
    
    // Initialize window
    adrp    x0, window_title@PAGE
    add     x0, x0, window_title@PAGEOFF
    mov     w1, #WINDOW_WIDTH
    mov     w2, #WINDOW_HEIGHT
    bl      _gfx_init
    
    cmp     x0, #0
    b.eq    init_ok
    
    adrp    x0, msg_error@PAGE
    add     x0, x0, msg_error@PAGEOFF
    bl      _print_str
    bl      _print_newline
    mov     w0, #1
    b       exit_program
    
init_ok:
    // Create texture for blitting framebuffer
    mov     w0, #WINDOW_WIDTH
    mov     w1, #WINDOW_HEIGHT
    bl      _gfx_create_texture
    cbz     x0, init_failed
    
    // Initialize software rasterizer
    mov     w0, #WINDOW_WIDTH
    mov     w1, #WINDOW_HEIGHT
    bl      _raster_init
    cbz     x0, init_failed
    
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
// Main loop
// ============================================================================
game_loop:
    // Handle window events (close button)
    bl      _events_poll
    bl      _events_should_quit
    cbnz    w0, quit_game
    
    // Update keyboard state
    bl      _keyboard_update
    
    // Check quit keys (ESC, Q)
    bl      _keyboard_get_state
    mov     x2, x0
    ldrb    w0, [x2, #KEY_ESCAPE]
    cbnz    w0, quit_game
    ldrb    w0, [x2, #KEY_Q]
    cbnz    w0, quit_game
    
    // Handle movement
    bl      handle_movement
    
    // ========== Render ==========
    
    // Clear framebuffer
    mov     w0, #20                  // R
    mov     w1, #22                  // G
    mov     w2, #30                  // B
    mov     w3, #255                 // A
    bl      _raster_set_color
    bl      _raster_clear
    
    // Background circles
    mov     w0, #40
    mov     w1, #45
    mov     w2, #60
    mov     w3, #255
    bl      _raster_set_color
    
    mov     w0, #150
    mov     w1, #150
    mov     w2, #80
    bl      _raster_circle
    
    mov     w0, #650
    mov     w1, #450
    mov     w2, #100
    bl      _raster_circle
    
    // Diagonal lines
    mov     w0, #60
    mov     w1, #65
    mov     w2, #80
    mov     w3, #255
    bl      _raster_set_color
    
    mov     w0, #0
    mov     w1, #0
    mov     w2, #200
    mov     w3, #150
    bl      _raster_line
    
    mov     w0, #800
    mov     w1, #0
    mov     w2, #600
    mov     w3, #150
    bl      _raster_line
    
    // Main square (cyan)
    mov     w0, #0
    mov     w1, #230
    mov     w2, #200
    mov     w3, #255
    bl      _raster_set_color
    
    adrp    x4, square_x@PAGE
    add     x4, x4, square_x@PAGEOFF
    ldr     w0, [x4]
    adrp    x4, square_y@PAGE
    add     x4, x4, square_y@PAGEOFF
    ldr     w1, [x4]
    mov     w2, #DEFAULT_SQUARE_SIZE
    mov     w3, #DEFAULT_SQUARE_SIZE
    bl      _raster_rect
    
    // Square outline (white)
    mov     w0, #255
    mov     w1, #255
    mov     w2, #255
    mov     w3, #255
    bl      _raster_set_color
    
    adrp    x4, square_x@PAGE
    add     x4, x4, square_x@PAGEOFF
    ldr     w0, [x4]
    adrp    x4, square_y@PAGE
    add     x4, x4, square_y@PAGEOFF
    ldr     w1, [x4]
    mov     w2, #DEFAULT_SQUARE_SIZE
    mov     w3, #DEFAULT_SQUARE_SIZE
    bl      _raster_rect_outline
    
    // Circle above square (coral)
    mov     w0, #255
    mov     w1, #100
    mov     w2, #100
    mov     w3, #255
    bl      _raster_set_color
    
    adrp    x4, square_x@PAGE
    add     x4, x4, square_x@PAGEOFF
    ldr     w0, [x4]
    add     w0, w0, #(DEFAULT_SQUARE_SIZE / 2)
    adrp    x4, square_y@PAGE
    add     x4, x4, square_y@PAGEOFF
    ldr     w1, [x4]
    sub     w1, w1, #30
    mov     w2, #15
    bl      _raster_circle_filled
    
    // ========== Blit to screen ==========
    
    bl      _raster_get_buffer
    mov     x19, x0
    
    adrp    x0, _fb_pitch@PAGE
    add     x0, x0, _fb_pitch@PAGEOFF
    ldr     w1, [x0]
    
    mov     x0, x19
    bl      _gfx_blit
    
    // Frame delay (~60 FPS)
    mov     w0, #16
    bl      _SDL_Delay
    
    b       game_loop

init_failed:
    adrp    x0, msg_error@PAGE
    add     x0, x0, msg_error@PAGEOFF
    bl      _print_str
    bl      _print_newline
    mov     w0, #1
    b       cleanup

quit_game:
    adrp    x0, msg_quit@PAGE
    add     x0, x0, msg_quit@PAGEOFF
    bl      _print_str
    bl      _print_newline
    mov     w0, #0
    
cleanup:
    stp     x19, x20, [sp, #-16]!
    mov     w19, w0
    
    bl      _raster_free
    bl      _gfx_quit
    
    mov     w0, w19
    ldp     x19, x20, [sp], #16
    
exit_program:
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// handle_movement - Update position based on keyboard state
// ============================================================================
.align 4
handle_movement:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    // Load position
    adrp    x19, square_x@PAGE
    add     x19, x19, square_x@PAGEOFF
    ldr     w21, [x19]
    
    adrp    x20, square_y@PAGE
    add     x20, x20, square_y@PAGEOFF
    ldr     w22, [x20]
    
    // Get key states
    bl      _keyboard_get_state
    mov     x2, x0
    
    // Left (arrow or A)
    ldrb    w3, [x2, #KEY_LEFT]
    ldrb    w4, [x2, #KEY_A]
    orr     w3, w3, w4
    cbz     w3, check_right
    sub     w21, w21, #MOVE_SPEED
    cmp     w21, #0
    csel    w21, wzr, w21, lt
    
check_right:
    ldrb    w3, [x2, #KEY_RIGHT]
    ldrb    w4, [x2, #KEY_D]
    orr     w3, w3, w4
    cbz     w3, check_up
    add     w21, w21, #MOVE_SPEED
    mov     w4, #(WINDOW_WIDTH - DEFAULT_SQUARE_SIZE)
    cmp     w21, w4
    csel    w21, w4, w21, gt
    
check_up:
    ldrb    w3, [x2, #KEY_UP]
    ldrb    w4, [x2, #KEY_W]
    orr     w3, w3, w4
    cbz     w3, check_down
    sub     w22, w22, #MOVE_SPEED
    cmp     w22, #0
    csel    w22, wzr, w22, lt
    
check_down:
    ldrb    w3, [x2, #KEY_DOWN]
    ldrb    w4, [x2, #KEY_S]
    orr     w3, w3, w4
    cbz     w3, movement_done
    add     w22, w22, #MOVE_SPEED
    mov     w4, #(WINDOW_HEIGHT - DEFAULT_SQUARE_SIZE)
    cmp     w22, w4
    csel    w22, w4, w22, gt
    
movement_done:
    str     w21, [x19]
    str     w22, [x20]
    
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// Data
// ============================================================================
.data
.align 4
square_x:       .word 0
square_y:       .word 0

window_title:   .asciz "ASM Graphics Demo"
msg_init:       .asciz "[INFO] Initializing..."
msg_ready:      .asciz "[INFO] Ready! Arrows/WASD to move, ESC/Q to quit."
msg_error:      .asciz "[ERROR] Failed to initialize!"
msg_quit:       .asciz "[INFO] Shutting down..."
