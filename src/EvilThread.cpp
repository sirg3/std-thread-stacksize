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

#include "EvilThread.hpp"
#include <mach/mach.h>

void *evil::details::AllocateStack(std::size_t size)
{
	vm_address_t addr = 0xB0000000; // PTHREAD_STACK_HINT
	int kr = vm_allocate(mach_task_self(),
	                     &addr,
	                     size,
	                     VM_MAKE_TAG(VM_MEMORY_STACK) | VM_FLAGS_ANYWHERE);
	if (kr != KERN_SUCCESS) return nullptr;

	// Use one page for a guard page.
	(void)vm_protect(mach_task_self(), addr, vm_page_size, FALSE, VM_PROT_NONE);

	return reinterpret_cast<void *>(addr + size);
}

void evil::details::FreeStack(void *stack, std::size_t size)
{
	(void)vm_deallocate(
	    mach_task_self(), reinterpret_cast<vm_address_t>(stack) - size, size);
}
