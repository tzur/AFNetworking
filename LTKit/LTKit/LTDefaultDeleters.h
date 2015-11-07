// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Mechanism for creating \c std::default_delete specializations for iOS classes that require manual
// reference counting. This allows to avoid using the <Type>Ref opaque pointer type, which hides
// handling raw pointers, and instead introduces \c std::unique_ptr as a way to manage these
// pointers in a safer way.
//
// The purpose of the unique pointer in this context is to balance a retain call (usually, the one
// that is performed for the caller when the object is created) with a release call. Since the
// objects are refcounted, is it possible that additional retain and release calls will occur in
// the unique pointer lifetime, and it is also possible that the unique pointer deleter will not
// cause the object to be destroyed, leaving it with a refcount of above 0.
//
// Do:
//
// 1. Wrap raw pointers with unique pointers to verify a retain call is balanced with a release:
//    @code@
//    std::unique_ptr<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
//    @endcode@
//
// 2. When in need to pass a managed manually refcounted object to another method or function, pass
//    either a raw pointer (not-sink) or the unique pointer by value (sink semantics), depending on
//    the desired usage. In almost all cases, the first option will be selected.
//
//    Example for raw pointer passing:
//
//    @code@
//    void foo() {
//      std::unique_ptr<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
//
//      // Call the method with the raw pointer.
//      needColorSpace(std::move(colorSpace));
//
//      // The ownership of \c colorSpace has been transferred to \c needColorSpace. You must not
//      // access \c colorSpace anymore in this function.
//    }
//
//    void needColorSpace(std::unique_ptr<CGColorSpaceRef> colorSpace) {
//      // Work with \c colorSpace. No additional retain or release is needed, since this function
//      // took ownership over \c colorSpace. Note that \c std::unique_ptr is passed by value.
//    }
//    @endcode@
//
//    Example for sink semantics:
//
//    @code@
//    void foo() {
//      std::unique_ptr<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
//
//      // Call the method while keeping the responsibility for releasing the object in this
//      // function.
//      needColorSpace(colorSpace.get());
//    }
//
//    void needColorSpace(CGColorSpaceRef colorSpace) {
//      // Work with \c colorSpace. No additional retain or release is needed, since the above
//      // unique_ptr will release the object after this method returns.
//    }
//    @endcode@
//
//    For more information about pointer ownership and semantics, see
//    http://herbsutter.com/2013/06/05/gotw-91-solution-smart-pointer-parameters/.
//
//
// 3. Don't fear from calling release functions that normally crash with \c nullptr. The
//    implementation of \c std::unique_ptr deleter is called only if the managed pointer is not
//    \c nullptr, avoiding the need to check for nullability.
//
// Don't:
//
// 1. Wrap raw pointers with \c std::unique_ptr without retaining the object first (or creating it,
//    which implicitly retains it as well). For example, the following code should be frowned upon:
//
//    @code
//    void LTBadDontDoIt(CGContextRef context) {
//      // Bad, since this will cause an additional release (and eventually \c context will be
//      // double-freed).
//      std::unique_ptr<CGContext> holdContext(context);
//    }
//    @endcode

/// Creates an \c std::default_delete specialization for the given \c TYPE pointer type with the
/// given \c RELEASE_FUNCTION, an unary function that accepts a pointer to type \c TYPE and releases
/// the object.
#define LTMakeDefaultDelete(TYPE, RELEASE_FUNCTION) \
  template <> \
  struct std::default_delete<TYPE> { \
    inline constexpr default_delete() noexcept = default; \
    \
    template <class _Up> \
    inline default_delete(const default_delete<_Up>&, \
      typename enable_if<is_convertible<_Up *, TYPE *>::value>::type* = 0) noexcept {} \
    \
    inline void operator() (TYPE *__ptr) const noexcept { \
      RELEASE_FUNCTION(__ptr); \
    } \
  };

// Core Graphics.
LTMakeDefaultDelete(CGColorSpace, CGColorSpaceRelease);
LTMakeDefaultDelete(CGContext, CGContextRelease);
LTMakeDefaultDelete(CGDataProvider, CGDataProviderRelease);
LTMakeDefaultDelete(CGImage, CGImageRelease);
LTMakeDefaultDelete(CGPath, CGPathRelease);
LTMakeDefaultDelete(CGGradient, CGGradientRelease);
