// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Mechanism for creating smart references for iOS classes that require manual reference counting.
// This allows to avoid using the <Type>Ref opaque pointer type, which hides handling raw pointers,
// and instead introduces an \c lt::Ref as a way to manage these pointers in a safer way.
//
// Adding new reference types:
//
// There are two ways to add a new reference type:
// 1. If the reference is a Core Foundation object, add a specialization for the type trait
//    \c IsCoreFoundationObjectRef for the object type and publicly inherit from \c std::true_type.
//    The type will be released with \c CFRelease.
// 2. To add a new reference type with a custom releaser, define a specialization of the
//    \c lt::RefReleaser class by the auxiliary macro \c LTMakeRefRelease. The macro accepts the
//    reference type and the release function, which is an unary function that decreases the retain
//    count of the object by 1.

#ifdef __cplusplus

namespace lt {

#pragma mark -
#pragma mark Type traits
#pragma mark -

/// Type trait indicating if the type is a reference to a Core Foundation Object.
template <typename T>
struct IsCoreFoundationObjectRef : public std::false_type {};

// Core Graphics.
template <> struct IsCoreFoundationObjectRef<CGColorSpaceRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGContextRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGDataProviderRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGImageRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGPathRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGMutablePathRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGGradientRef> : public std::true_type {};

#pragma mark -
#pragma mark RefReleaser
#pragma mark -

/// Base template for \c RefReleaser classes. This class should be specialized on the type of \c Ref
/// that is managed, and contain an \c operator() that releases that ref.
template <typename T, bool UseCFRelease = false>
struct RefReleaser {
};

/// Creates a \c RefReleaser specialization for the given \c TYPE pointer type with the given
/// \c RELEASE_FUNCTION, an unary function that accepts a pointer to type \c TYPE and releases
/// the object. \c RELEASE_FUNCTION will never be called with \c nullptr argument, thus no manual
/// null-check is required.
#define LTMakeRefReleaser(TYPE, RELEASE_FUNCTION) \
  template <> \
  struct ::lt::RefReleaser<TYPE, false> { \
    constexpr RefReleaser() noexcept = default; \
  \
    template <typename U> \
    constexpr RefReleaser(const RefReleaser<U*> &, \
        typename std::enable_if<std::is_convertible<U*, TYPE>::value>::type* = 0) noexcept {} \
  \
    inline void operator()(TYPE ptr) const noexcept { \
      RELEASE_FUNCTION(ptr); \
    } \
  };

/// RefReleaser for Core Foundation objects that are released with \c CFRelease.
template <typename T>
struct RefReleaser<T, true> {
  /// Default constructor. Required since there's an explicit copy constructor.
  constexpr RefReleaser() noexcept = default;

  /// Copy constructor allowing copying the releaser to a different type of \c Ref.
  template <typename U, bool UseCFRelease>
  constexpr RefReleaser(const RefReleaser<U, UseCFRelease> &,
                        typename std::enable_if<std::is_convertible<U, T>::value>::type* = 0)
      noexcept {}

  /// Releaser () operator which releases \c ptr.
  inline void operator()(T ptr) const noexcept {
    CFRelease(ptr);
  }
};

#pragma mark -
#pragma mark Ref
#pragma mark -

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
///      needColorSpace(colorSpace.get());
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
/// 3. Return \c lt::Ref from factory methods or functions that create a manually refcounted object.
///    Example:
///
///    @code@
///    lt::Ref<CGColorSpace> LTCreateColorSpaceWithFoo(Foo *foo);
///    @endcode@
///
///    For more information about this convention, see section #2 here:
///    http://herbsutter.com/2013/05/30/gotw-90-solution-factories/
///
/// 4. Don't fear from calling release functions that normally crash with \c nullptr. The
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

  /// Type of the ref releaser used by this Ref.
  typedef RefReleaser<T*, IsCoreFoundationObjectRef<T*>::value> RefReleaserType;

  /// Constructs a Ref with a \c nullptr reference.
  Ref() noexcept = default;

  /// Constructs a Ref with a given \c ref.
  explicit Ref(T *ref) noexcept : _unique_ptr(ref) {
  }

  /// Disallows copying a \c Ref.
  Ref(const Ref &ref) = delete;

  /// Move constructor which constructs a new \c Ref from an rvalue by stealing its underlying ref.
  Ref(Ref &&ref) noexcept : _unique_ptr(std::move(ref._unique_ptr)) {
  }

  /// Move constructor which constructs a new \c Ref from an rvalue by stealing its underlying ref.
  /// This move constructor supports type covariance by allowing to move a \c Ref from type \c U to
  /// type \c T, if \c U is convertible to \c T.
  template <typename U>
  Ref(Ref<U*> &&ref,
      typename std::enable_if<
        std::is_convertible<typename Ref<U*>::PointerType, PointerType>::value
      >::type * = 0) noexcept :
      _unique_ptr(std::move(ref._unique_ptr)) {
  }

  /// Disallows assigning a \c Ref.
  Ref &operator=(const Ref &ref) = delete;

  /// Move assignment operator, which steals the reference from \c ref. This move assignment
  /// operator supports type covariance by allowing to move assign a \c Ref from type \c U to
  /// type \c T, if \c U is convertible to \c T.
  template <typename U>
  typename std::enable_if<
    std::is_convertible<typename Ref<U*>::PointerType, PointerType>::value, Ref &
  >::type
  operator=(Ref<U*> &&ref) noexcept {
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

  /// Releases the ownership of the managed object if it exists and returns the pointer to the
  /// managed reference. After this call, this object will not own a reference.
  PointerType release() noexcept {
    return _unique_ptr.release();
  }

  /// Resets the Ref by releasing the previously held reference and acquiring the given \c ref. If
  /// Ref is currently pointing to \c nullptr, no action is performed.
  void reset(T *ref) noexcept {
    _unique_ptr.reset(ref);
  }

private:
  /// Allows accessing private members of \c Ref<U> from \c Ref<T>.
  template <typename U>
  friend class Ref;

  /// Type of unique pointer that is contained in this class.
  typedef std::unique_ptr<T, RefReleaserType> UniquePtrType;

  /// Unique pointer which is held by this Ref.
  UniquePtrType _unique_ptr;
};

} // namespace lt

#endif
