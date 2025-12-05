// ============================================================================
// window.s - Window management (SDL2 wrapper)
// ============================================================================
// Functions:
//   gfx_init      - Initialize graphics system
//   gfx_quit      - Shutdown graphics system
//   gfx_clear     - Clear the window with a color
//   gfx_present   - Present the rendered frame
//   gfx_set_color - Set the current drawing color
// ============================================================================

.global _gfx_init
.global _gfx_quit
.global _gfx_clear
.global _gfx_present
.global _gfx_set_color
.global _gfx_window
.global _gfx_renderer

.include "include/constants.inc"

.text

// ============================================================================
// _gfx_init - Initialize SDL2 and create window/renderer
// Input:  x0 = pointer to window title string
//         w1 = window width
//         w2 = window height
// Output: x0 = 0 on success, -1 on failure
// ============================================================================
.align 4
_gfx_init:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    mov     x19, x0                  // Save title
    mov     w20, w1                  // Save width
    mov     w21, w2                  // Save height
    
    // SDL_Init(SDL_INIT_VIDEO)
    mov     w0, #SDL_INIT_VIDEO
    bl      _SDL_Init
    cbnz    w0, init_failed
    
    // SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w, h, flags)
    mov     x0, x19                  // title
    mov     w1, #0x2FFF0000          // SDL_WINDOWPOS_CENTERED (encoded)
    movk    w1, #0x2FFF, lsl #16
    mov     w2, w1                   // SDL_WINDOWPOS_CENTERED
    mov     w3, w20                  // width
    mov     w4, w21                  // height
    mov     w5, #SDL_WINDOW_SHOWN    // flags
    bl      _SDL_CreateWindow
    cbz     x0, init_failed
    
    // Store window pointer
    adrp    x1, _gfx_window@PAGE
    add     x1, x1, _gfx_window@PAGEOFF
    str     x0, [x1]
    mov     x19, x0                  // Save window for renderer creation
    
    // SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)
    mov     x0, x19                  // window
    mov     w1, #-1                  // index (-1 = first available)
    mov     w2, #0x6                 // SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    bl      _SDL_CreateRenderer
    cbz     x0, init_failed
    
    // Store renderer pointer
    adrp    x1, _gfx_renderer@PAGE
    add     x1, x1, _gfx_renderer@PAGEOFF
    str     x0, [x1]
    
    mov     x0, #0                   // Success
    b       init_done
    
init_failed:
    mov     x0, #-1                  // Failure
    
init_done:
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _gfx_quit - Cleanup and shutdown SDL2
// Input:  none
// Output: none
// ============================================================================
.align 4
_gfx_quit:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Destroy renderer
    adrp    x0, _gfx_renderer@PAGE
    add     x0, x0, _gfx_renderer@PAGEOFF
    ldr     x0, [x0]
    cbz     x0, 1f
    bl      _SDL_DestroyRenderer
    
1:
    // Destroy window
    adrp    x0, _gfx_window@PAGE
    add     x0, x0, _gfx_window@PAGEOFF
    ldr     x0, [x0]
    cbz     x0, 2f
    bl      _SDL_DestroyWindow
    
2:
    // SDL_Quit
    bl      _SDL_Quit
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _gfx_clear - Clear the window with current color
// Input:  none (uses current render color)
// Output: none
// ============================================================================
.align 4
_gfx_clear:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    adrp    x0, _gfx_renderer@PAGE
    add     x0, x0, _gfx_renderer@PAGEOFF
    ldr     x0, [x0]
    bl      _SDL_RenderClear
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _gfx_present - Present the rendered frame
// Input:  none
// Output: none
// ============================================================================
.align 4
_gfx_present:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    adrp    x0, _gfx_renderer@PAGE
    add     x0, x0, _gfx_renderer@PAGEOFF
    ldr     x0, [x0]
    bl      _SDL_RenderPresent
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _gfx_set_color - Set the current drawing color
// Input:  w0 = red (0-255)
//         w1 = green (0-255)
//         w2 = blue (0-255)
//         w3 = alpha (0-255)
// Output: none
// ============================================================================
.align 4
_gfx_set_color:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    // Save color components
    mov     w19, w0                  // red
    mov     w20, w1                  // green
    mov     w21, w2                  // blue
    mov     w22, w3                  // alpha
    
    // SDL_SetRenderDrawColor(renderer, r, g, b, a)
    adrp    x0, _gfx_renderer@PAGE
    add     x0, x0, _gfx_renderer@PAGEOFF
    ldr     x0, [x0]
    mov     w1, w19
    mov     w2, w20
    mov     w3, w21
    mov     w4, w22
    bl      _SDL_SetRenderDrawColor
    
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// Data section
// ============================================================================
.data
.align 8
_gfx_window:    .quad 0
_gfx_renderer:  .quad 0

