#std-thread-stacksize
##Introduction

C++11's `std::thread` class does not provide a way to specify the stack size for
a created thread. On OS X and iOS, all threads created via `std::thread` get an
unalterable 512KiB for stack space.

This is a toy project that allows customizable stack size in C++14 code without
undefined behavior or patching code. It's implemented by having the
`std::thread` call a trampoline that sets up an entirely new stack than the
underlying pthread's. As such, APIs like `pthread_get_stacksize_np` and
`pthread_get_stackaddr_np` will return 'incorrect' results.

It's probably a bad idea to use this in production code.

##Portability

This has been lightly tested on OS X and iOS. Adding support for other platforms
would require writing the appropriate trampoline function in assembly and
functions to allocate and free 'stack' memory.

## License

This code is released under the zlib license. To see the exact details, look at
the `LICENSE` file.
