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

#ifndef EvilThread_hpp
#define EvilThread_hpp

#include <array>
#include <cstddef>
#include <exception>
#include <functional>
#include <memory>
#include <new>
#include <thread>
#include <tuple>
#include <type_traits>
#include <utility>

namespace evil {

#if defined(__clang__)
#define EVIL_HAS_EXCEPTIONS __has_feature(cxx_exceptions)
#elif defined(_MSC_VER)
#define EVIL_HAS_EXCEPTIONS defined(_CPPUNWIND)
#elif defined(__GNUC__)
#define EVIL_HAS_EXCEPTIONS defined(__EXCEPTIONS)
#else
#define EVIL_HAS_EXCEPTIONS 1
#endif

namespace details {
	// Voodoo to emulate C++17's std::invoke, taken from cppreference.com's
	// documentation.
	// <http://en.cppreference.com/w/cpp/utility/functional/invoke>
	template <class F, class... Args>
	inline auto INVOKE(F &&f, Args &&... args)
	    -> decltype(std::forward<F>(f)(std::forward<Args>(args)...))
	{
		return std::forward<F>(f)(std::forward<Args>(args)...);
	}

	template <class Base, class T, class Derived>
	inline auto INVOKE(T Base::*pmd, Derived &&ref)
	    -> decltype(std::forward<Derived>(ref).*pmd)
	{
		return std::forward<Derived>(ref).*pmd;
	}

	template <class PMD, class Pointer>
	inline auto INVOKE(PMD pmd, Pointer &&ptr)
	    -> decltype((*std::forward<Pointer>(ptr)).*pmd)
	{
		return (*std::forward<Pointer>(ptr)).*pmd;
	}

	template <class Base, class T, class Derived, class... Args>
	inline auto INVOKE(T Base::*pmf, Derived &&ref, Args &&... args)
	    -> decltype((std::forward<Derived>(ref).*
	                 pmf)(std::forward<Args>(args)...))
	{
		return (std::forward<Derived>(ref).*pmf)(std::forward<Args>(args)...);
	}

	template <class PMF, class Pointer, class... Args>
	inline auto INVOKE(PMF pmf, Pointer &&ptr, Args &&... args)
	    -> decltype(((*std::forward<Pointer>(ptr)).*
	                 pmf)(std::forward<Args>(args)...))
	{
		return ((*std::forward<Pointer>(ptr)).*
		        pmf)(std::forward<Args>(args)...);
	}

	template <class F, class... ArgTypes>
	decltype(auto) cxx1z_invoke(F &&f, ArgTypes &&... args)
	{
		return INVOKE(std::forward<F>(f), std::forward<ArgTypes>(args)...);
	}

	// Specified in [thread.decaycopy] as part of std::thread's constructor
	// behavior.
	template <class T>
	std::decay_t<T> decay_copy(T &&v)
	{
		return std::forward<T>(v);
	}

	// Helper function to split the function and arguments and invoke the
	// function.
	template <class FP, class... Args, size_t... Indices>
	void thread_execute(std::tuple<FP, Args...> &t,
	                    std::index_sequence<Indices...>)
	{
		cxx1z_invoke(std::move(std::get<0>(t)),
		             std::move(std::get<1 + Indices>(t))...);
	}

	// The function invoked by our assembly stub.
	template <class PackTy>
	void thread_main(void *vp)
	{
		std::unique_ptr<PackTy> pack(static_cast<PackTy *>(vp));
		thread_execute(
		    *pack,
		    std::make_index_sequence<std::tuple_size<PackTy>::value - 1>());
	}

	extern "C" void ThreadTrampoline(void (*fp)(void *),
	                                 void *arg,
	                                 void *stack,
	                                 std::size_t size);
	void *AllocateStack(std::size_t size);
	extern "C" void FreeStack(void *stack, std::size_t size);
} // namespace details

/// Creates and runs a new thread with the specified stack size.
///
/// \param stackSize The stack size to use, in bytes. This should be a multiple
/// of the page size.
/// \param func The function object to invoke.
/// \param args The arguments to pass to the invocation.
/// \return A valid thread object.
///
/// \warning This probably shouldn't be used in practice because \c
/// pthread_get_stacksize_np and
///          \c pthread_get_stackaddr_np return the values the underlying thread
///          was created with.
template <class FP, class... Args>
std::thread create_thread(std::size_t stackSize, FP &&func, Args &&... args)
{
	typedef std::tuple<typename std::decay<FP>::type,
	                   typename std::decay<Args>::type...>
	    PackTy;

	void *stack = details::AllocateStack(stackSize);
	if (!stack) {
#if EVIL_HAS_EXCEPTIONS
		throw std::bad_alloc();
#else
		std::terminate();
#endif
	}

	std::thread result;
	std::unique_ptr<PackTy> pack;

#if EVIL_HAS_EXCEPTIONS
	try {
#endif
		pack = std::make_unique<PackTy>(
		    details::decay_copy(std::forward<FP>(func)),
		    details::decay_copy(std::forward<Args>(args))...);

		result = std::thread(&details::ThreadTrampoline,
		                     &details::thread_main<PackTy>,
		                     pack.get(),
		                     stack,
		                     stackSize);
#if EVIL_HAS_EXCEPTIONS
	} catch (...) {
		details::FreeStack(stack, stackSize);
		throw;
	}
#endif

	pack.release();
	return result;
}

#undef EVIL_HAS_EXCEPTIONS

} // namespace evil

#endif // defined(EvilThread_hpp)
