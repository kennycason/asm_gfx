// ============================================================================
// print.s - Console printing utilities
// ============================================================================
// Functions:
//   print_str     - Print a null-terminated string
//   print_newline - Print a newline character
//   print_int     - Print an integer (decimal)
// ============================================================================

.global _print_str
.global _print_newline
.global _print_int
.global _print_hex

.include "include/constants.inc"

.text

// ============================================================================
// _print_str - Print a null-terminated string to stdout
// Input:  x0 = pointer to null-terminated string
// Output: none
// ============================================================================
.align 4
_print_str:
    stp     x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!   // Save callee-saved registers
    
    mov     x19, x0                  // Save string pointer
    
    // Calculate string length
    mov     x20, #0                  // Length counter
1:
    ldrb    w1, [x19, x20]          // Load byte at offset
    cbz     w1, 2f                   // If null, done counting
    add     x20, x20, #1             // Increment counter
    b       1b
    
2:
    // Write syscall: write(STDOUT, str, len)
    mov     x0, #STDOUT              // File descriptor
    mov     x1, x19                  // String pointer
    mov     x2, x20                  // Length
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    ldp     x19, x20, [sp], #16      // Restore callee-saved
    ldp     x29, x30, [sp], #16      // Restore frame pointer and return
    ret

// ============================================================================
// _print_newline - Print a newline character
// Input:  none
// Output: none
// ============================================================================
.align 4
_print_newline:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    
    adrp    x0, newline_char@PAGE
    add     x0, x0, newline_char@PAGEOFF
    mov     x1, #1
    mov     x2, x1
    mov     x0, #STDOUT
    adrp    x1, newline_char@PAGE
    add     x1, x1, newline_char@PAGEOFF
    mov     x2, #1
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _print_int - Print an integer in decimal
// Input:  x0 = integer to print
// Output: none
// ============================================================================
.align 4
_print_int:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    mov     x19, x0                  // Save the number
    
    // Handle negative numbers
    cmp     x19, #0
    b.ge    1f
    
    // Print minus sign
    adrp    x0, minus_char@PAGE
    add     x0, x0, minus_char@PAGEOFF
    mov     x2, #1
    mov     x1, x0
    mov     x0, #STDOUT
    mov     x16, #SYS_WRITE
    svc     #0x80
    neg     x19, x19                 // Make positive
    
1:
    // Convert to string (reverse order into buffer)
    adrp    x20, int_buffer@PAGE
    add     x20, x20, int_buffer@PAGEOFF
    add     x20, x20, #20            // Start at end of buffer
    mov     x21, #0                  // Digit count
    mov     x22, #10                 // Divisor
    
    // Handle zero specially
    cbnz    x19, 2f
    sub     x20, x20, #1
    mov     w1, #'0'
    strb    w1, [x20]
    mov     x21, #1
    b       3f
    
2:
    cbz     x19, 3f                  // Done when number is 0
    udiv    x1, x19, x22             // x1 = x19 / 10
    msub    x2, x1, x22, x19         // x2 = x19 - (x1 * 10) = remainder
    add     w2, w2, #'0'             // Convert to ASCII
    sub     x20, x20, #1             // Move buffer pointer back
    strb    w2, [x20]                // Store digit
    mov     x19, x1                  // Update number
    add     x21, x21, #1             // Increment digit count
    b       2b
    
3:
    // Print the buffer
    mov     x0, #STDOUT
    mov     x1, x20                  // Buffer start
    mov     x2, x21                  // Length
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// _print_hex - Print an integer in hexadecimal
// Input:  x0 = integer to print
// Output: none
// ============================================================================
.align 4
_print_hex:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    stp     x19, x20, [sp, #-16]!
    stp     x21, x22, [sp, #-16]!
    
    mov     x19, x0                  // Save the number
    
    // Print "0x" prefix
    mov     x0, #STDOUT
    adrp    x1, hex_prefix@PAGE
    add     x1, x1, hex_prefix@PAGEOFF
    mov     x2, #2
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    // Convert to hex string
    adrp    x20, int_buffer@PAGE
    add     x20, x20, int_buffer@PAGEOFF
    add     x20, x20, #16            // Start at end of buffer
    mov     x21, #0                  // Digit count
    
    // Handle zero specially
    cbnz    x19, 1f
    sub     x20, x20, #1
    mov     w1, #'0'
    strb    w1, [x20]
    mov     x21, #1
    b       2f
    
1:
    cbz     x19, 2f
    and     x1, x19, #0xF            // Get low nibble
    cmp     x1, #10
    b.lt    1f
    add     w1, w1, #('a' - 10)      // a-f
    b       3f
1:
    add     w1, w1, #'0'             // 0-9
3:
    sub     x20, x20, #1
    strb    w1, [x20]
    lsr     x19, x19, #4             // Shift right by 4
    add     x21, x21, #1
    cbnz    x19, 1b
    
2:
    // Print the buffer
    mov     x0, #STDOUT
    mov     x1, x20
    mov     x2, x21
    mov     x16, #SYS_WRITE
    svc     #0x80
    
    ldp     x21, x22, [sp], #16
    ldp     x19, x20, [sp], #16
    ldp     x29, x30, [sp], #16
    ret

// ============================================================================
// Data section
// ============================================================================
.data
newline_char:   .ascii "\n"
minus_char:     .ascii "-"
hex_prefix:     .ascii "0x"

.bss
int_buffer:     .space 24

