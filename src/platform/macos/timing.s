// ============================================================================
// timing.s - Timing functions
// ============================================================================
// Uses libc usleep for reliable delays.
//
// Functions:
//   timing_sleep_ms - Sleep for milliseconds
//   timing_sleep_us - Sleep for microseconds
// ============================================================================

.global _timing_sleep_ms
.global _timing_sleep_us

.text

// ============================================================================
// _timing_sleep_ms - Sleep for specified milliseconds
// Input:  w0 = milliseconds to sleep
// Output: none
// ============================================================================
.align 4
_timing_sleep_ms:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Convert ms to us: us = ms * 1000
    mov     w1, #1000
    mul     w0, w0, w1
    
    // Call usleep(microseconds)
    bl      _usleep
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _timing_sleep_us - Sleep for specified microseconds
// Input:  w0 = microseconds to sleep
// Output: none
// ============================================================================
.align 4
_timing_sleep_us:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    // Call usleep(microseconds)
    bl      _usleep
    
    ldp     x29, x30, [sp], #16
    ret
