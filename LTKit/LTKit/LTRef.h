// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Mechanism for creating smart references for iOS classes that require manual reference counting.
// This allows to avoid using the <Type>Ref opaque pointer type, which hides handling raw pointers,
// and instead introduces an \c lt::Ref as a way to manage these pointers in a safer way.
//
// Adding new reference types:
//
// To add a new reference type, one should define a specialization of the \c lt::RefReleaser class
// by the auxiliary macro \c LTMakeRefRelease. The macro accepts the reference type and the release
// function, which is an unary function that decreases the retain count of the object by 1.

#ifdef __cplusplus

namespace lt {

/// Base template for \c RefReleaser classes. This class should be specialized on the type of \c Ref
/// that is managed, and contain an \c operator() that releases that ref.
template <typename T>
struct RefReleaser {
};

/// Creates a \c RefReleaser specialization for the given \c TYPE pointer type with the given
/// \c RELEASE_FUNCTION, an unary function that accepts a pointer to type \c TYPE and releases
/// the object. \c RELEASE_FUNCTION will never be called with \c nullptr argument, thus no manual
/// null-check is required.
#define LTMakeRefReleaser(TYPE, RELEASE_FUNCTION) \
  template <> \
  struct ::lt::RefReleaser<TYPE> { \
    inline void operator()(TYPE ptr) const noexcept { \
      RELEASE_FUNCTION(ptr); \
    } \
  };

/// Base template for \c Ref classes. Since Ref is templated only on pointer types, use the Ref<T*>
/// specialization instead.
template <typename T>
class Ref {
  static_assert(std::is_pointer<T>::value, "Ref should be templated only on pointer types");
};

/// Smart pointer that retains a reference and is responsible for releasing it. A reference is an
/// externally managed object that has a retain count, and is disposed by that external system when
/// its retain count reaches 0. The purpose of this smart pointer is to balance a retain call
/// (usually, the one that is performed for the caller when the object is created) with a release
/// call. Since the objects are refcounted, is it possible that additional retain and release calls
/// will occur in the Ref's lifetime, and it is also possible that the Ref's releaser will not cause
/// the object to be destroyed, leaving it with a retain count of above 0.
///
/// Do:
///
/// 1. Wrap raw pointers with \c lt::Ref to verify a retain call is balanced with a release:
///    @code@
///    lt::Ref<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
///    @endcode@
///
/// 2. When in need to pass a managed manually refcounted object to another method or function, pass
///    either a raw pointer (not-sink) or the Ref by value (sink semantics), depending on the
///    desired usage. In almost all cases, the first option will be selected.
///
///    Example for raw pointer passing:
///
///    @code@
///    void foo() {
///      lt::Ref<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
///
///      // Call the method with the raw pointer.
///      needColorSpace(std::move(colorSpace));
///
///      // The ownership of \c colorSpace has been transferred to \c needColorSpace. You must not
///      // access \c colorSpace anymore in this function.
///    }
///
///    void needColorSpace(lt::Ref<CGColorSpaceRef> colorSpace) {
///      // Work with \c colorSpace. No additional retain or release is needed, since this function
///      // took ownership over \c colorSpace. Note that \c lt::Ref is passed by value.
///    }
///    @endcode@
///
///    Example for sink semantics:
///
///    @code@
///    void foo() {
///      lt::Ref<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
///
///      // Call the method while keeping the responsibility for releasing the object in this
///      // scope.
///      needColorSpace(colorSpace.get()); // or just needColorSpace(colorSpace);
///    }
///
///    void needColorSpace(CGColorSpaceRef colorSpace) {
///      // Work with \c colorSpace. No additional retain or release is needed, since the above
///      // lt::Ref will release the object after this method returns.
///    }
///    @endcode@
///
///    For more information about pointer ownership and semantics, see
///    http://herbsutter.com/2013/06/05/gotw-91-solution-smart-pointer-parameters/.
///
///
/// 3. Don't fear from calling release functions that normally crash with \c nullptr. The
///    implementation of \c lt::Ref releaser is called only if the managed pointer is not \c
///    nullptr, avoiding the need to check for nullability.
///
/// Don't:
///
/// 1. Wrap raw pointers with \c lt::Ref without retaining the object first (or creating it, which
///    implicitly retains it as well). For example, the following code should be frowned upon:
///
///    @code
///    void LTBadDontDoIt(CGContextRef context) {
///      // Bad, since this will cause an additional release (and eventually \c context will be
///      // double-freed).
///      lt::Ref<CGContext> holdContext(context);
///    }
///    @endcode
///
/// @note in contrast to std::unique_ptr, this class is templated on the reference type, and not on
/// the element type the reference points to. This is because, in iOS, we almost always don't have
/// access to the actual element type, and the reference type points to an opaque object.
template <typename T>
class Ref<T*> {
public:
  /// Type of the pointer this Ref holds, i.e. T*.
  typedef T *PointerType;

  /// Constructs a Ref with a \c nullptr reference.
  Ref() noexcept = default;

  /// Constructs a Ref with a given \c ref.
  explicit Ref(T *ref) noexcept : _unique_ptr(ref) {
  }

  /// Disallows copying a \c Ref.
  Ref(const Ref &ref) = delete;

  /// Move constructor which constructs a new Ref from an rvalue by stealing its underlying ref.
  Ref(Ref &&ref) noexcept : _unique_ptr(std::move(ref._unique_ptr)) {
  }

  /// Disallows assigning a \c Ref.
  Ref &operator=(const Ref &ref) = delete;

  /// Move assignment operator, which steals the reference from \c ref.
  Ref &operator=(Ref &&ref) noexcept {
    _unique_ptr = std::move(ref._unique_ptr);
    return *this;
  }

  /// \c true if this class currently owns a reference.
  explicit operator bool() const noexcept {
    return (bool)_unique_ptr;
  }

  /// Returns the owned reference.
  T *get() const noexcept {
    return _unique_ptr.get();
  }

  /// Implicit cast operator to the underlying Ref. One can use this operator to easily use refs
  /// when passing them to methods without the need to call \c get().
  operator T *() const noexcept {
    return get();
  }

  /// Resets the Ref by releasing the previously held reference and acquiring the given \c ref. If
  /// Ref is currently pointing to \c nullptr, no action is performed.
  void reset(T *ref) noexcept {
    _unique_ptr.reset(ref);
  }

private:
  /// Type of unique pointer that is contained in this class.
  typedef std::unique_ptr<T, RefReleaser<T*>> UniquePtrType;

  /// Unique pointer which is held by this Ref.
  UniquePtrType _unique_ptr;
};

// Core Graphics.
LTMakeRefReleaser(CGColorSpaceRef, CGColorSpaceRelease);
LTMakeRefReleaser(CGContextRef, CGContextRelease);
LTMakeRefReleaser(CGDataProviderRef, CGDataProviderRelease);
LTMakeRefReleaser(CGImageRef, CGImageRelease);
LTMakeRefReleaser(CGPathRef, CGPathRelease);
LTMakeRefReleaser(CGMutablePathRef, CGPathRelease);
LTMakeRefReleaser(CGGradientRef, CGGradientRelease);

} // namespace lt

#endif
