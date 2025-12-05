// ============================================================================
// demo.s - Maze Game
// ============================================================================
// Navigate through a randomly generated maze!
// Controls: Arrow keys/WASD to move, R to regenerate, ESC/Q to quit
// ============================================================================

.global _main

.include "include/constants.inc"

// Tile and player constants
.set TILE_SIZE,     16
.set PLAYER_SIZE,   8
.set PLAYER_OFFSET, 4           // Center player in tile: (16-8)/2

.text

// ============================================================================
// _main - Entry point
// ============================================================================
.align 4
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    adrp    x0, msg_init@PAGE
    add     x0, x0, msg_init@PAGEOFF
    bl      _print_str
    bl      _print_newline
    
    // Seed random number generator
    mov     x0, #0
    bl      _time
    bl      _srand
    
    // Initialize window
    adrp    x0, window_title@PAGE
    add     x0, x0, window_title@PAGEOFF
    mov     w1, #WINDOW_WIDTH
    mov     w2, #WINDOW_HEIGHT
    bl      _window_init
    cmp     x0, #0
    b.ne    init_error
    
    // Initialize rasterizer
    mov     w0, #WINDOW_WIDTH
    mov     w1, #WINDOW_HEIGHT
    bl      _raster_init
    cbz     x0, init_error
    
    // Initialize maze
    bl      _maze_init
    cmp     x0, #0
    b.ne    init_error
    
    // Generate first maze
    bl      _maze_generate
    
    // Set player to start position
    bl      reset_player
    
    adrp    x0, msg_ready@PAGE
    add     x0, x0, msg_ready@PAGEOFF
    bl      _print_str
    bl      _print_newline

// ============================================================================
// Main game loop
// ============================================================================
game_loop:
    bl      _window_poll
    bl      _window_should_close
    cbnz    w0, quit_game
    
    bl      _keyboard_update
    
    // Check quit keys
    bl      _keyboard_get_state
    mov     x2, x0
    ldrb    w0, [x2, #KEY_ESCAPE]
    cbnz    w0, quit_game
    ldrb    w0, [x2, #KEY_Q]
    cbnz    w0, quit_game
    
    // Check R for regenerate
    mov     w0, #KEY_R
    bl      _keyboard_just_pressed
    cbz     w0, no_regen
    bl      _maze_generate
    bl      reset_player
    adrp    x0, msg_regen@PAGE
    add     x0, x0, msg_regen@PAGEOFF
    bl      _print_str
    bl      _print_newline
no_regen:
    
    // Handle player movement
    bl      handle_movement
    
    // Check win condition
    bl      check_win
    
    // ========== Render ==========
    bl      render_game
    
    // Blit to screen
    bl      _raster_get_buffer
    mov     x19, x0
    adrp    x0, _fb_pitch@PAGE
    add     x0, x0, _fb_pitch@PAGEOFF
    ldr     w3, [x0]
    mov     x0, x19
    mov     w1, #WINDOW_WIDTH
    mov     w2, #WINDOW_HEIGHT
    bl      _window_blit
    
    // Frame delay
    mov     w0, #16
    bl      _timing_sleep_ms
    
    b       game_loop

init_error:
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
    bl      _maze_free
    bl      _raster_free
    bl      _window_quit
    mov     w0, w19
    ldp     x19, x20, [sp], #16
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// reset_player - Reset player to start position
// ============================================================================
.align 4
reset_player:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Get start position
    adrp    x0, _maze_start_x@PAGE
    add     x0, x0, _maze_start_x@PAGEOFF
    ldr     w1, [x0]
    adrp    x0, _maze_start_y@PAGE
    add     x0, x0, _maze_start_y@PAGEOFF
    ldr     w2, [x0]
    
    // Set player tile position
    adrp    x0, player_tile_x@PAGE
    add     x0, x0, player_tile_x@PAGEOFF
    str     w1, [x0]
    adrp    x0, player_tile_y@PAGE
    add     x0, x0, player_tile_y@PAGEOFF
    str     w2, [x0]
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// handle_movement - Move player if valid (with cooldown for controlled speed)
// ============================================================================
.align 4
handle_movement:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    stp     x23, x24, [sp, #-16]!
    
    // Check cooldown - decrement and skip if not zero
    adrp    x0, move_cooldown@PAGE
    add     x0, x0, move_cooldown@PAGEOFF
    ldr     w1, [x0]
    cbz     w1, cooldown_ready
    sub     w1, w1, #1
    str     w1, [x0]
    b       movement_skip
    
cooldown_ready:
    // Load current position
    adrp    x19, player_tile_x@PAGE
    add     x19, x19, player_tile_x@PAGEOFF
    ldr     w21, [x19]
    adrp    x20, player_tile_y@PAGE
    add     x20, x20, player_tile_y@PAGEOFF
    ldr     w22, [x20]
    
    // Get key state
    bl      _keyboard_get_state
    mov     x23, x0
    
    // Check Left (held)
    ldrb    w0, [x23, #KEY_LEFT]
    ldrb    w1, [x23, #KEY_A]
    orr     w0, w0, w1
    cbz     w0, check_move_right
    sub     w0, w21, #1
    mov     w1, w22
    bl      _maze_get_tile
    cmp     w0, #1                   // TILE_WALL
    b.eq    check_move_right
    sub     w21, w21, #1
    b       did_move
    
check_move_right:
    ldrb    w0, [x23, #KEY_RIGHT]
    ldrb    w1, [x23, #KEY_D]
    orr     w0, w0, w1
    cbz     w0, check_move_up
    add     w0, w21, #1
    mov     w1, w22
    bl      _maze_get_tile
    cmp     w0, #1
    b.eq    check_move_up
    add     w21, w21, #1
    b       did_move
    
check_move_up:
    ldrb    w0, [x23, #KEY_UP]
    ldrb    w1, [x23, #KEY_W]
    orr     w0, w0, w1
    cbz     w0, check_move_down
    mov     w0, w21
    sub     w1, w22, #1
    bl      _maze_get_tile
    cmp     w0, #1
    b.eq    check_move_down
    sub     w22, w22, #1
    b       did_move
    
check_move_down:
    ldrb    w0, [x23, #KEY_DOWN]
    ldrb    w1, [x23, #KEY_S]
    orr     w0, w0, w1
    cbz     w0, movement_skip
    mov     w0, w21
    add     w1, w22, #1
    bl      _maze_get_tile
    cmp     w0, #1
    b.eq    movement_skip
    add     w22, w22, #1
    
did_move:
    // Store new position
    str     w21, [x19]
    str     w22, [x20]
    
    // Reset cooldown (4 frames between moves)
    adrp    x0, move_cooldown@PAGE
    add     x0, x0, move_cooldown@PAGEOFF
    mov     w1, #4
    str     w1, [x0]
    
movement_skip:
    ldp     x23, x24, [sp], #16
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// check_win - Check if player reached the end
// ============================================================================
.align 4
check_win:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Get player position
    adrp    x0, player_tile_x@PAGE
    add     x0, x0, player_tile_x@PAGEOFF
    ldr     w1, [x0]
    adrp    x0, player_tile_y@PAGE
    add     x0, x0, player_tile_y@PAGEOFF
    ldr     w2, [x0]
    
    // Get end position
    adrp    x0, _maze_end_x@PAGE
    add     x0, x0, _maze_end_x@PAGEOFF
    ldr     w3, [x0]
    adrp    x0, _maze_end_y@PAGE
    add     x0, x0, _maze_end_y@PAGEOFF
    ldr     w4, [x0]
    
    // Compare
    cmp     w1, w3
    b.ne    not_win
    cmp     w2, w4
    b.ne    not_win
    
    // Win! Print message and regenerate
    adrp    x0, msg_win@PAGE
    add     x0, x0, msg_win@PAGEOFF
    bl      _print_str
    bl      _print_newline
    bl      _maze_generate
    bl      reset_player
    
not_win:
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// render_game - Render maze and player
// ============================================================================
.align 4
render_game:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    stp     x23, x24, [sp, #-16]!
    
    // Clear screen (dark background)
    mov     w0, #15
    mov     w1, #15
    mov     w2, #25
    mov     w3, #255
    bl      _raster_set_color
    bl      _raster_clear
    
    // Get maze data
    bl      _maze_get_data
    mov     x23, x0
    
    // Render maze tiles
    mov     w20, #0                  // y tile
render_y_loop:
    adrp    x0, _maze_height@PAGE
    add     x0, x0, _maze_height@PAGEOFF
    ldr     w0, [x0]
    cmp     w20, w0
    b.ge    render_maze_done
    
    mov     w21, #0                  // x tile
render_x_loop:
    adrp    x0, _maze_width@PAGE
    add     x0, x0, _maze_width@PAGEOFF
    ldr     w0, [x0]
    cmp     w21, w0
    b.ge    render_y_next
    
    // Get tile value
    adrp    x0, _maze_width@PAGE
    add     x0, x0, _maze_width@PAGEOFF
    ldr     w0, [x0]
    mul     w22, w20, w0
    add     w22, w22, w21
    ldrb    w24, [x23, x22]
    
    // Set color based on tile type
    cmp     w24, #1                  // Wall
    b.eq    set_wall_color
    cmp     w24, #2                  // Start
    b.eq    set_start_color
    cmp     w24, #3                  // End
    b.eq    set_end_color
    b       render_x_next           // Empty - don't draw
    
set_wall_color:
    mov     w0, #60
    mov     w1, #60
    mov     w2, #80
    mov     w3, #255
    bl      _raster_set_color
    b       draw_tile
    
set_start_color:
    mov     w0, #50
    mov     w1, #150
    mov     w2, #50
    mov     w3, #255
    bl      _raster_set_color
    b       draw_tile
    
set_end_color:
    mov     w0, #200
    mov     w1, #50
    mov     w2, #50
    mov     w3, #255
    bl      _raster_set_color
    
draw_tile:
    // Calculate pixel position
    mov     w0, w21
    lsl     w0, w0, #4               // x * 16
    mov     w1, w20
    lsl     w1, w1, #4               // y * 16
    mov     w2, #TILE_SIZE
    mov     w3, #TILE_SIZE
    bl      _raster_rect
    
render_x_next:
    add     w21, w21, #1
    b       render_x_loop
    
render_y_next:
    add     w20, w20, #1
    b       render_y_loop

render_maze_done:
    // Render player
    adrp    x0, player_tile_x@PAGE
    add     x0, x0, player_tile_x@PAGEOFF
    ldr     w19, [x0]
    adrp    x0, player_tile_y@PAGE
    add     x0, x0, player_tile_y@PAGEOFF
    ldr     w20, [x0]
    
    // Calculate pixel position (centered in tile)
    lsl     w19, w19, #4             // tile_x * 16
    add     w19, w19, #PLAYER_OFFSET // + 4 to center
    lsl     w20, w20, #4             // tile_y * 16
    add     w20, w20, #PLAYER_OFFSET
    
    // Draw body (cyan square)
    mov     w0, #0
    mov     w1, #220
    mov     w2, #200
    mov     w3, #255
    bl      _raster_set_color
    
    mov     w0, w19
    add     w1, w20, #4              // Body below head
    mov     w2, #PLAYER_SIZE
    mov     w3, #PLAYER_SIZE
    bl      _raster_rect
    
    // Draw head (coral circle)
    mov     w0, #255
    mov     w1, #100
    mov     w2, #100
    mov     w3, #255
    bl      _raster_set_color
    
    add     w0, w19, #4              // Center x
    add     w1, w20, #2              // Head y
    mov     w2, #4                   // radius
    bl      _raster_circle_filled
    
    ldp     x23, x24, [sp], #16
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// Data
// ============================================================================
.data
.align 4
player_tile_x:  .word 1
player_tile_y:  .word 1
move_cooldown:  .word 0

window_title:   .asciz "ASM Maze Game"
msg_init:       .asciz "[INFO] Starting maze game..."
msg_ready:      .asciz "[INFO] Arrows/WASD: move, R: new maze, ESC: quit"
msg_error:      .asciz "[ERROR] Failed to initialize!"
msg_quit:       .asciz "[INFO] Thanks for playing!"
msg_regen:      .asciz "[INFO] New maze generated!"
msg_win:        .asciz "[INFO] You WIN! Generating new maze..."
