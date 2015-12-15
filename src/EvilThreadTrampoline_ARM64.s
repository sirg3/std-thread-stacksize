//
//  EvilThreadTrampoline_ARM64.s
//  threads
//
//  Created by Joseph Ranieri on 12/7/15.
//  Copyright (c) 2015 Joseph Ranieri. All rights reserved.
//

#ifdef __arm64__

; void ThreadTrampoline(void *arg, void (*fp)(void *), void *stack, size_t stackSize);
;
; |---------| <- x2 on entry
; |  size   |
; |---------|
; | prev sp |
; |---------|
; | prev lr |
; |---------|
; | prev fp |
; |---------| <- sp and fp will point here, giving us a frame pointer
; |         |
; |vvvvvvvvv|

.align 2
.globl _ThreadTrampoline
_ThreadTrampoline:
    ; set up the saved stack frame
    stp fp, lr, [x2, #-32]!
    mov fp, x2

    ; we need to save the original stack pointer to restore later and the size
	; argument
	mov x17, sp
    stp x17, x3, [x2, #16]

    ; swap out the stacks
	mov sp, x2

	; invoke our target function
    blr x1

    ; restore the previous frame
	ldp fp, lr, [sp]

	; load the original stack pointer into x17 and the size argument back to x1
	ldp x17, x1, [sp, #16]

	; recalculate the original stack argument into x0
    add x0, sp, #32

	; swap the stacks back to the real one
	mov sp, x17

	; by this point, the stack argument is in x0 and the size argument in x1
    b _FreeStack

#endif
