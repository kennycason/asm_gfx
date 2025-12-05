// ============================================================================
// demo.s - Demo entry point: Software rendered movable square
// ============================================================================
// A demo showing our custom software rasterizer:
//   - Our own framebuffer
//   - Our own pixel plotting
//   - Our own shape drawing (rect, circle, line)
//   - Arrow keys to move
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
    
    // Initialize graphics (SDL window)
    adrp    x0, window_title@PAGE
    add     x0, x0, window_title@PAGEOFF
    mov     w1, #WINDOW_WIDTH
    mov     w2, #WINDOW_HEIGHT
    bl      _gfx_init
    
    // Check for init failure
    cmp     x0, #0
    b.eq    init_ok
    
    adrp    x0, msg_error@PAGE
    add     x0, x0, msg_error@PAGEOFF
    bl      _print_str
    bl      _print_newline
    mov     w0, #1
    b       exit_program
    
init_ok:
    // Create texture for blitting
    mov     w0, #WINDOW_WIDTH
    mov     w1, #WINDOW_HEIGHT
    bl      _gfx_create_texture
    cbz     x0, texture_failed
    
    // Initialize our software rasterizer framebuffer
    mov     w0, #WINDOW_WIDTH
    mov     w1, #WINDOW_HEIGHT
    bl      _raster_init
    cbz     x0, raster_failed
    
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
    
    // Initialize animation counter
    adrp    x0, frame_count@PAGE
    add     x0, x0, frame_count@PAGEOFF
    str     wzr, [x0]

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
    
    // Increment frame counter
    adrp    x0, frame_count@PAGE
    add     x0, x0, frame_count@PAGEOFF
    ldr     w1, [x0]
    add     w1, w1, #1
    str     w1, [x0]
    
    // ========== SOFTWARE RENDERING STARTS HERE ==========
    
    // Clear framebuffer (dark background)
    mov     w0, #20                  // R
    mov     w1, #22                  // G
    mov     w2, #30                  // B
    mov     w3, #255                 // A
    bl      _raster_set_color
    bl      _raster_clear
    
    // Draw some decorative circles in background
    mov     w0, #40                  // R
    mov     w1, #45                  // G
    mov     w2, #60                  // B
    mov     w3, #255                 // A
    bl      _raster_set_color
    
    mov     w0, #150                 // cx
    mov     w1, #150                 // cy
    mov     w2, #80                  // radius
    bl      _raster_circle
    
    mov     w0, #650                 // cx
    mov     w1, #450                 // cy
    mov     w2, #100                 // radius
    bl      _raster_circle
    
    // Draw diagonal lines
    mov     w0, #60                  // R
    mov     w1, #65                  // G
    mov     w2, #80                  // B
    mov     w3, #255                 // A
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
    
    // Draw the main square (filled, bright cyan)
    mov     w0, #0                   // R
    mov     w1, #230                 // G
    mov     w2, #200                 // B
    mov     w3, #255                 // A
    bl      _raster_set_color
    
    // Load square position
    adrp    x4, square_x@PAGE
    add     x4, x4, square_x@PAGEOFF
    ldr     w0, [x4]
    adrp    x4, square_y@PAGE
    add     x4, x4, square_y@PAGEOFF
    ldr     w1, [x4]
    mov     w2, #DEFAULT_SQUARE_SIZE
    mov     w3, #DEFAULT_SQUARE_SIZE
    bl      _raster_rect
    
    // Draw square outline (white)
    mov     w0, #255                 // R
    mov     w1, #255                 // G
    mov     w2, #255                 // B
    mov     w3, #255                 // A
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
    
    // Draw a filled circle that follows the square
    mov     w0, #255                 // R
    mov     w1, #100                 // G
    mov     w2, #100                 // B
    mov     w3, #255                 // A
    bl      _raster_set_color
    
    adrp    x4, square_x@PAGE
    add     x4, x4, square_x@PAGEOFF
    ldr     w0, [x4]
    add     w0, w0, #(DEFAULT_SQUARE_SIZE / 2)  // Center x
    adrp    x4, square_y@PAGE
    add     x4, x4, square_y@PAGEOFF
    ldr     w1, [x4]
    sub     w1, w1, #30              // Above the square
    mov     w2, #15                  // radius
    bl      _raster_circle_filled
    
    // ========== BLIT TO SCREEN ==========
    
    // Get framebuffer and pitch
    bl      _raster_get_buffer
    mov     x19, x0                  // Save buffer pointer
    
    adrp    x0, _fb_pitch@PAGE
    add     x0, x0, _fb_pitch@PAGEOFF
    ldr     w1, [x0]                 // pitch
    
    mov     x0, x19                  // buffer
    bl      _gfx_blit
    
    // Small delay
    mov     w0, #16                  // ~60 FPS
    bl      _SDL_Delay
    
    b       game_loop

texture_failed:
raster_failed:
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
    mov     w19, w0                  // Save exit code
    
    // Free rasterizer
    bl      _raster_free
    
    // Cleanup SDL
    bl      _gfx_quit
    
    mov     w0, w19                  // Restore exit code
    ldp     x19, x20, [sp], #16
    
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
frame_count:    .word 0

window_title:   .asciz "ASM Software Rasterizer Demo"
msg_init:       .asciz "[INFO] Initializing software rasterizer..."
msg_ready:      .asciz "[INFO] Ready! Arrow keys to move, ESC to quit."
msg_error:      .asciz "[ERROR] Failed to initialize!"
msg_quit:       .asciz "[INFO] Shutting down..."
