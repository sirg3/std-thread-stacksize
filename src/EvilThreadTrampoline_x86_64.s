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

#if defined(__x86_64__)

# void ThreadTrampoline(void *arg, void (*fp)(void *), void *stack, size_t stackSize);
# rdi = fp
# rsi = arg
# rdx = stack
# rcx = stackSize
#
.globl _ThreadTrampoline
_ThreadTrampoline:
    # Store the original stack size and our custom stack size
    movq %rdx, -8(%rdx)
    movq %rcx, -16(%rdx)

    # Store the original stack address in order to revert to it later.
    movq %rsp, -24(%rdx)

    # Copy over the original return address so that stack traces look right.
    movq (%rsp), %rax
    movq %rax, -32(%rdx)

    # Start using our custom stack.
    movq %rdx, %rsp
    subq $32, %rsp

    # Happily invoke the target.
    call *%rsi

    # Grab the original stack and size so that we can pass them off to the
    # FreeStack function.
    movq 24(%rsp), %rdi
    movq 16(%rsp), %rsi

    # Now restore the original stack pointer.
    movq 8(%rsp), %rsp

    # Now tail call out of here and free the custom stack.
    jmp _FreeStack

#endif
