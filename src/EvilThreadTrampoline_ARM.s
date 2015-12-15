//
//  Argh.s
//  threads
//
//  Created by Joseph Ranieri on 10/24/15.
//  Copyright (c) 2015 Joseph Ranieri. All rights reserved.
//

#ifdef __arm__

# void ThreadTrampoline(void *arg, void (*fp)(void *), void *stack, size_t stackSize);
#
# |---------| <- r2 on entry
# | prev lr |
# |---------|
# | prev r7 |
# |---------| <- r7 will point here, giving us a frame pointer
# | prev sp |
# |---------|
# |  size   |
# |---------| <- sp will point here
# |         |
# |vvvvvvvvv|

.align 2
.globl _ThreadTrampoline
_ThreadTrampoline:
	# set up the saved stack frame
    stmfd r2!, { r7, lr }
    mov r7, r2

	# save off the size argument and the origianl stack pointer
    stmfd r2!, { r3, sp }

	# swap out the stack and invoke our target
	mov sp, r2

	# invoke our target function
    blx r1

	# store the fake stack off into r0
	mov r0, sp

	# read the size argument into r1 (not r3) and set sp to our original stack
    ldmfd r0!, { r1, sp }

    # restore the previous frame
	ldmfd r0!, { r7, lr }
 
	# and off we go with the arguments in place
    b _FreeStack

#endif
