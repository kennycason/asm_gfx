// ============================================================================
// draw.s - Drawing primitives
// ============================================================================
// Functions:
//   draw_rect       - Draw a filled rectangle
//   draw_rect_outline - Draw a rectangle outline
//   draw_line       - Draw a line
//   draw_point      - Draw a single point
// ============================================================================

.global _draw_rect
.global _draw_rect_outline
.global _draw_line
.global _draw_point

.include "include/constants.inc"

.text

// ============================================================================
// _draw_rect - Draw a filled rectangle
// Input:  w0 = x position
//         w1 = y position
//         w2 = width
//         w3 = height
// Output: none
// ============================================================================
.align 4
_draw_rect:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #16              // Allocate space for SDL_Rect
    
    // Store rect values on stack (SDL_Rect: x, y, w, h - each 4 bytes)
    str     w0, [sp, #0]             // x
    str     w1, [sp, #4]             // y
    str     w2, [sp, #8]             // w
    str     w3, [sp, #12]            // h
    
    // SDL_RenderFillRect(renderer, &rect)
    adrp    x0, _gfx_renderer@PAGE
    add     x0, x0, _gfx_renderer@PAGEOFF
    ldr     x0, [x0]
    mov     x1, sp                   // Pointer to rect
    bl      _SDL_RenderFillRect
    
    add     sp, sp, #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _draw_rect_outline - Draw a rectangle outline (not filled)
// Input:  w0 = x position
//         w1 = y position
//         w2 = width
//         w3 = height
// Output: none
// ============================================================================
.align 4
_draw_rect_outline:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #16              // Allocate space for SDL_Rect
    
    // Store rect values on stack
    str     w0, [sp, #0]             // x
    str     w1, [sp, #4]             // y
    str     w2, [sp, #8]             // w
    str     w3, [sp, #12]            // h
    
    // SDL_RenderDrawRect(renderer, &rect)
    adrp    x0, _gfx_renderer@PAGE
    add     x0, x0, _gfx_renderer@PAGEOFF
    ldr     x0, [x0]
    mov     x1, sp                   // Pointer to rect
    bl      _SDL_RenderDrawRect
    
    add     sp, sp, #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _draw_line - Draw a line between two points
// Input:  w0 = x1
//         w1 = y1
//         w2 = x2
//         w3 = y2
// Output: none
// ============================================================================
.align 4
_draw_line:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    // Save coordinates
    mov     w19, w0                  // x1
    mov     w20, w1                  // y1
    mov     w21, w2                  // x2
    mov     w22, w3                  // y2
    
    // SDL_RenderDrawLine(renderer, x1, y1, x2, y2)
    adrp    x0, _gfx_renderer@PAGE
    add     x0, x0, _gfx_renderer@PAGEOFF
    ldr     x0, [x0]
    mov     w1, w19
    mov     w2, w20
    mov     w3, w21
    mov     w4, w22
    bl      _SDL_RenderDrawLine
    
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _draw_point - Draw a single point
// Input:  w0 = x
//         w1 = y
// Output: none
// ============================================================================
.align 4
_draw_point:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    
    mov     w19, w0                  // x
    mov     w20, w1                  // y
    
    // SDL_RenderDrawPoint(renderer, x, y)
    adrp    x0, _gfx_renderer@PAGE
    add     x0, x0, _gfx_renderer@PAGEOFF
    ldr     x0, [x0]
    mov     w1, w19
    mov     w2, w20
    bl      _SDL_RenderDrawPoint
    
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

