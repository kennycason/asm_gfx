// ============================================================================
// window.s - Native macOS window using Cocoa (Objective-C runtime)
// ============================================================================
// Uses objc_msgSend to interact with NSApplication, NSWindow, etc.
//
// Functions:
//   window_init     - Create window and initialize Cocoa
//   window_blit     - Copy framebuffer to window
//   window_poll     - Poll and process events
//   window_should_close - Check if window should close
//   window_quit     - Cleanup
// ============================================================================

.global _window_init
.global _window_blit
.global _window_poll
.global _window_should_close
.global _window_quit

.include "include/constants.inc"

.text

// ============================================================================
// Cocoa/CoreGraphics constants
// ============================================================================
.set NSWindowStyleMaskTitled,           1
.set NSWindowStyleMaskClosable,         2
.set NSWindowStyleMaskMiniaturizable,   4
.set NSBackingStoreBuffered,            2
.set NSApplicationActivationPolicyRegular, 0

// CGBitmapInfo values
// kCGImageAlphaNoneSkipFirst = 6 (XRGB, ignore alpha, RGB in bytes 1-3)
// kCGBitmapByteOrder32Big = 16384 (4 << 12) - read as big-endian
// This expects 0xXXRRGGBB format which we output
.set kCGBitmapInfo_XRGB,                16390

// ============================================================================
// _window_init - Initialize Cocoa and create window
// Input:  x0 = title string (C string)
//         w1 = width
//         w2 = height
// Output: x0 = 0 on success, -1 on failure
// ============================================================================
.align 4
_window_init:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    stp     x23, x24, [sp, #-16]!
    
    mov     x19, x0                  // title
    mov     w20, w1                  // width
    mov     w21, w2                  // height
    
    // Store dimensions
    adrp    x0, _win_width@PAGE
    add     x0, x0, _win_width@PAGEOFF
    str     w20, [x0]
    adrp    x0, _win_height@PAGE
    add     x0, x0, _win_height@PAGEOFF
    str     w21, [x0]
    
    // [NSApplication sharedApplication]
    adrp    x0, str_NSApplication@PAGE
    add     x0, x0, str_NSApplication@PAGEOFF
    bl      _objc_getClass
    cbz     x0, init_failed
    mov     x22, x0
    
    adrp    x0, sel_sharedApplication@PAGE
    add     x0, x0, sel_sharedApplication@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x22
    bl      _objc_msgSend
    cbz     x0, init_failed
    
    adrp    x1, _nsapp@PAGE
    add     x1, x1, _nsapp@PAGEOFF
    str     x0, [x1]
    mov     x22, x0
    
    // [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular]
    adrp    x0, sel_setActivationPolicy@PAGE
    add     x0, x0, sel_setActivationPolicy@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x22
    mov     x2, #NSApplicationActivationPolicyRegular
    bl      _objc_msgSend
    
    // Create NSWindow: [[NSWindow alloc] initWithContentRect:styleMask:backing:defer:]
    adrp    x0, str_NSWindow@PAGE
    add     x0, x0, str_NSWindow@PAGEOFF
    bl      _objc_getClass
    cbz     x0, init_failed
    mov     x23, x0
    
    // alloc
    adrp    x0, sel_alloc@PAGE
    add     x0, x0, sel_alloc@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x23
    bl      _objc_msgSend
    cbz     x0, init_failed
    mov     x23, x0
    
    // initWithContentRect:styleMask:backing:defer:
    // NSRect passed in d0-d3 on ARM64
    adrp    x0, sel_initWithContentRect@PAGE
    add     x0, x0, sel_initWithContentRect@PAGEOFF
    bl      _sel_registerName
    mov     x24, x0
    
    mov     x0, x23                  // receiver
    mov     x1, x24                  // selector
    
    // NSRect: origin.x, origin.y, size.width, size.height as doubles in d0-d3
    mov     w2, #100
    scvtf   d0, w2                   // x = 100.0
    scvtf   d1, w2                   // y = 100.0
    scvtf   d2, w20                  // width
    scvtf   d3, w21                  // height
    
    mov     x2, #(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable)
    mov     x3, #NSBackingStoreBuffered
    mov     x4, #0                   // defer = NO
    bl      _objc_msgSend
    cbz     x0, init_failed
    
    adrp    x1, _nswindow@PAGE
    add     x1, x1, _nswindow@PAGEOFF
    str     x0, [x1]
    mov     x23, x0
    
    // Set window title
    adrp    x0, str_NSString@PAGE
    add     x0, x0, str_NSString@PAGEOFF
    bl      _objc_getClass
    mov     x24, x0
    
    adrp    x0, sel_stringWithUTF8String@PAGE
    add     x0, x0, sel_stringWithUTF8String@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x24
    mov     x2, x19
    bl      _objc_msgSend
    mov     x24, x0
    
    adrp    x0, sel_setTitle@PAGE
    add     x0, x0, sel_setTitle@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x23
    mov     x2, x24
    bl      _objc_msgSend
    
    // Get content view (we'll draw directly to it)
    adrp    x0, sel_contentView@PAGE
    add     x0, x0, sel_contentView@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x23
    bl      _objc_msgSend
    
    adrp    x1, _contentview@PAGE
    add     x1, x1, _contentview@PAGEOFF
    str     x0, [x1]
    
    // [window makeKeyAndOrderFront:nil]
    adrp    x0, sel_makeKeyAndOrderFront@PAGE
    add     x0, x0, sel_makeKeyAndOrderFront@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x23
    mov     x2, #0
    bl      _objc_msgSend
    
    // [NSApp activateIgnoringOtherApps:YES]
    adrp    x0, sel_activateIgnoringOtherApps@PAGE
    add     x0, x0, sel_activateIgnoringOtherApps@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    adrp    x0, _nsapp@PAGE
    add     x0, x0, _nsapp@PAGEOFF
    ldr     x0, [x0]
    mov     x2, #1
    bl      _objc_msgSend
    
    // [NSApp finishLaunching] - needed for proper event handling
    adrp    x0, sel_finishLaunching@PAGE
    add     x0, x0, sel_finishLaunching@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    adrp    x0, _nsapp@PAGE
    add     x0, x0, _nsapp@PAGEOFF
    ldr     x0, [x0]
    bl      _objc_msgSend
    
    mov     x0, #0
    b       init_done
    
init_failed:
    mov     x0, #-1
    
init_done:
    ldp     x23, x24, [sp], #16
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _window_blit - Copy framebuffer to window using CALayer
// Input:  x0 = pointer to ARGB pixel data
//         w1 = width
//         w2 = height
//         w3 = pitch (bytes per row)
// Output: none
// ============================================================================
.align 4
_window_blit:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    stp     x23, x24, [sp, #-16]!
    stp     x25, x26, [sp, #-16]!
    
    mov     x19, x0                  // pixel data
    mov     w20, w1                  // width
    mov     w21, w2                  // height
    mov     w22, w3                  // pitch
    
    // Create CGColorSpace
    bl      _CGColorSpaceCreateDeviceRGB
    cbz     x0, blit_done
    mov     x23, x0
    
    // Create CGDataProvider from our buffer
    // CGDataProviderCreateWithData(info, data, size, releaseData)
    mov     x0, #0                   // info = NULL
    mov     x1, x19                  // data
    mov     w2, w22                  // pitch
    mov     w3, w21                  // height
    mul     w2, w2, w3               // size = pitch * height
    mov     x3, #0                   // releaseData = NULL (we manage memory)
    bl      _CGDataProviderCreateWithData
    cbz     x0, blit_cleanup_cs
    mov     x24, x0                  // data provider
    
    // Create CGImage
    // CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, 
    //               colorspace, bitmapInfo, provider, decode, shouldInterpolate, intent)
    mov     x0, x20                  // width
    mov     x1, x21                  // height
    mov     x2, #8                   // bitsPerComponent
    mov     x3, #32                  // bitsPerPixel
    mov     x4, x22                  // bytesPerRow
    mov     x5, x23                  // colorspace
    mov     x6, #kCGBitmapInfo_XRGB  // bitmapInfo
    mov     x7, x24                  // provider
    // Remaining args on stack
    sub     sp, sp, #32
    str     xzr, [sp, #0]            // decode = NULL
    mov     x25, #0
    str     x25, [sp, #8]            // shouldInterpolate = false
    str     xzr, [sp, #16]           // intent = default
    bl      _CGImageCreate
    add     sp, sp, #32
    cbz     x0, blit_cleanup_dp
    mov     x25, x0                  // CGImage
    
    // Get content view's layer
    adrp    x0, _contentview@PAGE
    add     x0, x0, _contentview@PAGEOFF
    ldr     x0, [x0]
    cbz     x0, blit_cleanup_img
    mov     x26, x0                  // content view
    
    // [view setWantsLayer:YES]
    adrp    x0, sel_setWantsLayer@PAGE
    add     x0, x0, sel_setWantsLayer@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x26
    mov     x2, #1
    bl      _objc_msgSend
    
    // [view layer]
    adrp    x0, sel_layer@PAGE
    add     x0, x0, sel_layer@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x26
    bl      _objc_msgSend
    cbz     x0, blit_cleanup_img
    mov     x26, x0                  // CALayer
    
    // [layer setContents:(id)cgImage]
    adrp    x0, sel_setContents@PAGE
    add     x0, x0, sel_setContents@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x26
    mov     x2, x25                  // CGImage as id
    bl      _objc_msgSend
    
    // [layer setContentsGravity:kCAGravityResizeAspect] - optional, for proper scaling
    // Skip for now - default should work
    
blit_cleanup_img:
    mov     x0, x25
    bl      _CGImageRelease
    
blit_cleanup_dp:
    mov     x0, x24
    bl      _CGDataProviderRelease
    
blit_cleanup_cs:
    mov     x0, x23
    bl      _CGColorSpaceRelease
    
blit_done:
    ldp     x25, x26, [sp], #16
    ldp     x23, x24, [sp], #16
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _window_poll - Poll for window events
// Input:  none
// Output: none
// ============================================================================
.align 4
_window_poll:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    
poll_loop:
    // [NSApp nextEventMatchingMask:untilDate:inMode:dequeue:]
    adrp    x0, sel_nextEventMatchingMask@PAGE
    add     x0, x0, sel_nextEventMatchingMask@PAGEOFF
    bl      _sel_registerName
    mov     x19, x0
    
    // Get NSDefaultRunLoopMode
    adrp    x0, _NSDefaultRunLoopMode@GOTPAGE
    ldr     x0, [x0, _NSDefaultRunLoopMode@GOTPAGEOFF]
    ldr     x20, [x0]
    
    adrp    x0, _nsapp@PAGE
    add     x0, x0, _nsapp@PAGEOFF
    ldr     x0, [x0]
    mov     x1, x19
    mov     x2, #-1                  // NSEventMaskAny
    movk    x2, #0xFFFF, lsl #16
    movk    x2, #0xFFFF, lsl #32
    movk    x2, #0xFFFF, lsl #48
    mov     x3, #0                   // untilDate: nil
    mov     x4, x20                  // inMode
    mov     x5, #1                   // dequeue: YES
    bl      _objc_msgSend
    
    cbz     x0, poll_done
    mov     x19, x0                  // event
    
    // Get event type to filter keyboard events
    adrp    x0, sel_type@PAGE
    add     x0, x0, sel_type@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x19
    bl      _objc_msgSend
    
    // NSEventTypeKeyDown = 10, NSEventTypeKeyUp = 11
    // Skip keyboard events (we handle them via CGEventSourceKeyState)
    cmp     x0, #10
    b.eq    poll_loop                // Skip keydown
    cmp     x0, #11
    b.eq    poll_loop                // Skip keyup
    cmp     x0, #12                  // NSEventTypeFlagsChanged
    b.eq    poll_loop                // Skip modifier keys
    
    // [NSApp sendEvent:event] for non-keyboard events
    adrp    x0, sel_sendEvent@PAGE
    add     x0, x0, sel_sendEvent@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    adrp    x0, _nsapp@PAGE
    add     x0, x0, _nsapp@PAGEOFF
    ldr     x0, [x0]
    mov     x2, x19
    bl      _objc_msgSend
    
    b       poll_loop
    
poll_done:
    // [NSApp updateWindows]
    adrp    x0, sel_updateWindows@PAGE
    add     x0, x0, sel_updateWindows@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    adrp    x0, _nsapp@PAGE
    add     x0, x0, _nsapp@PAGEOFF
    ldr     x0, [x0]
    bl      _objc_msgSend
    
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _window_should_close - Check if window should close
// Input:  none
// Output: w0 = 1 if should close, 0 otherwise
// ============================================================================
.align 4
_window_should_close:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    
    adrp    x0, _nswindow@PAGE
    add     x0, x0, _nswindow@PAGEOFF
    ldr     x19, [x0]
    cbz     x19, should_close_yes
    
    // [window isVisible]
    adrp    x0, sel_isVisible@PAGE
    add     x0, x0, sel_isVisible@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x19
    bl      _objc_msgSend
    
    cbnz    x0, should_close_no
    
should_close_yes:
    mov     w0, #1
    b       should_close_done
    
should_close_no:
    mov     w0, #0
    
should_close_done:
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _window_quit - Cleanup
// ============================================================================
.align 4
_window_quit:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    
    adrp    x0, _nswindow@PAGE
    add     x0, x0, _nswindow@PAGEOFF
    ldr     x19, [x0]
    cbz     x19, quit_done
    
    // [window close]
    adrp    x0, sel_close@PAGE
    add     x0, x0, sel_close@PAGEOFF
    bl      _sel_registerName
    mov     x1, x0
    mov     x0, x19
    bl      _objc_msgSend
    
quit_done:
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// Data
// ============================================================================
.data
.align 8
_nsapp:         .quad 0
_nswindow:      .quad 0
_contentview:   .quad 0
_win_width:     .word 0
_win_height:    .word 0

// Class names
str_NSApplication:      .asciz "NSApplication"
str_NSWindow:           .asciz "NSWindow"
str_NSString:           .asciz "NSString"

// Selectors
sel_sharedApplication:          .asciz "sharedApplication"
sel_setActivationPolicy:        .asciz "setActivationPolicy:"
sel_alloc:                      .asciz "alloc"
sel_initWithContentRect:        .asciz "initWithContentRect:styleMask:backing:defer:"
sel_stringWithUTF8String:       .asciz "stringWithUTF8String:"
sel_setTitle:                   .asciz "setTitle:"
sel_contentView:                .asciz "contentView"
sel_makeKeyAndOrderFront:       .asciz "makeKeyAndOrderFront:"
sel_activateIgnoringOtherApps:  .asciz "activateIgnoringOtherApps:"
sel_finishLaunching:            .asciz "finishLaunching"
sel_nextEventMatchingMask:      .asciz "nextEventMatchingMask:untilDate:inMode:dequeue:"
sel_sendEvent:                  .asciz "sendEvent:"
sel_updateWindows:              .asciz "updateWindows"
sel_isVisible:                  .asciz "isVisible"
sel_close:                      .asciz "close"
sel_setWantsLayer:              .asciz "setWantsLayer:"
sel_layer:                      .asciz "layer"
sel_setContents:                .asciz "setContents:"
sel_type:                       .asciz "type"
