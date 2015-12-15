// Copyright (c) 2015 Joe Ranieri
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
//   1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
//
//   2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
//
//   3. This notice may not be removed or altered from any source
//   distribution.
//

#if defined(__i386__)

# void ThreadTrampoline(void *arg, void (*fp)(void *), void *stack, size_t stackSize);
#
# Here's how we'll set up the stack. Having a stack frame isn't required, but
# the space needs to be there for alignment and it's much nicer.
#
# |----------|
# | prev EIP |
# |----------|
# | prev EBP |
# |----------| <- EBP will point here, giving us a stack frame.
# | prev ESP |
# |----------|
# |    arg   |
# |----------| <- ESP points here and it must be be 16-byte aligned.
# |          |
# |vvvvvvvvvv|
#

.globl _ThreadTrampoline
_ThreadTrampoline:
    # Grab our new stack pointer and start setting things up...
    movl 12(%esp), %eax
    subl $16, %eax

    # Set up our stack frame entry.
    movl 0(%esp), %ecx
    movl %ecx, 12(%eax)

    movl %ebp, 8(%eax)
    leal 8(%eax), %ebp

    # Stash away the real stack pointer.
    movl %esp, 4(%eax)

    # Copy the function argument to the new stack.
    movl 4(%esp), %ecx
    movl %ecx, 0(%eax)

    # Swap our stack and the fake one, then call through to our target.
    xchg %eax, %esp
    call *8(%eax)

    # Reload the real stack pointer.
    movl 4(%esp), %esp

    # We must restore EBP before jumping out of here. Otherwise it's going to be
    # pointing at a spot on the stack that got freed.
    movl 0(%ebp), %ebp

    # Move our fake stack pointer to be arg1
    movl 12(%esp), %ecx
    movl %ecx, 4(%esp)

    # And move the stack size to be arg2
    movl 16(%esp), %ecx
    movl %ecx, 8(%esp)

    jmp _FreeStack

#endif
