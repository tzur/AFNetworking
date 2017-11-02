// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDefines.h"

// Mechanism for creating smart references for iOS classes that require manual reference counting.
// This allows to avoid using the <Type>Ref opaque pointer type, which hides handling raw pointers,
// and instead introduces an \c lt::Ref as a way to manage these pointers in a safer way.
//
// To add a new type that is supported by lt::Ref, add a specialization to the type trait
// \c IsCoreFoundationObjectRef for the object type and publicly inherit from \c std::true_type.

#ifdef __cplusplus

namespace lt {

#pragma mark -
#pragma mark Type traits
#pragma mark -

/// Type trait indicating if the type is a reference to a Core Foundation Object.
template <typename T>
struct IsCoreFoundationObjectRef : public std::false_type {};

// Core Graphics.
template <> struct IsCoreFoundationObjectRef<CGColorRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGColorSpaceRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGContextRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGDataProviderRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGGradientRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGImageRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGPathRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CGMutablePathRef> : public std::true_type {};

#pragma mark -
#pragma mark Ref
#pragma mark -

/// Smart pointer that retains a reference and responsible for releasing it similarly to
/// \c std::shared_ptr, except that the reference count itself is managed by Core Foundation.
///
/// The purpose of this smart pointer is to balance a retain call (usually, the one that is
/// performed for the caller when the object is created) with a release call. Since the objects are
/// refcounted by Core Foundation, it is possible that additional retain and release calls will
/// occur in the Ref's lifetime outside the scope of the \c Ref, so it doesn't necessarily hold that
/// the refcount of the object before any \c Refs started managed the object will be equal to the
/// refcount after all of them were destroyed.
///
/// Like any other refcount mechanism, the underlying object will be deallocated once the refcount
/// has reached 0.
///
/// Usage examples:
///
/// 1. Wrapping a raw reference with \c Ref to verify a retain call is balanced with a release:
///    @code@
///    lt::Ref<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
///    @endcode@
///
/// 2. When in need to pass a refcounted object to another method or function, use the following
///    conventions:
///
///    Raw pointer passing:
///    @code@
///    void foo {
///      lt::Ref<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
///
///      needColorSpace(colorSpace.get());
///
///      // Underlying reference will be automatically released when this scope ends.
///    }
///
///    void needColorSpace(CGColorSpaceRef colorSpace) {
///      // Use colorSpace, but do not hold it.
///    }
///    @endcode@
///
///    This is the most common scenario, which indicates that the reference must outlive the callee.
///    It does not change the existing refcount of the object, and allows the callee to also accept
///    references that are not managed by \c Ref. For synchronous methods that do not require to
///    retain the reference, this should be the preferred solution.
///
///    Passing \c Ref by value:
///    @code@
///    void foo {
///      lt::Ref<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
///
///      storeColorSpace(colorSpace);
///
///      // colorSpace may be still alive after this scope ends.
///    }
///
///    void storeColorSpace(lt::Ref<CGColorSpaceRef> colorSpace) {
///      // Store colorSpace for use after the function has returned.
///    }
///    @endcode@
///
///    In cases where there's a need to store a reference to the argument to be used after the
///    callee has returned, pass the \c Ref by value. This will in turn increase the refcount which
///    may have performance impliciations.
///
///    If there's a chain of calls where the local scope of the function is not the final
///    destination, use \c std::move to avoid redundant retains and releases of the object:
///
///    @code@
///    void useColorSpace1(lt::Ref<CGColorSpaceRef> colorSpace) {
///      // colorSpace is already retained, so this adds a redundant retain and release.
///      useColorSpace2(colorSpace);
///
///      // Use move constructor instead and steal the reference. Note that you can no longer use
///      // colorSpace in this method.
///      useColorSpace2(std::move(colorSpace));
///    }
///
///    void useColorSpace2(lt::Ref<CGColorSpaceRef> colorSpace) {
///      // Store colorSpace for use after the function has returned.
///    }
///    @endcode@
///
///    Passing \c Ref by const reference:
///    @code@
///    void foo {
///      lt::Ref<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
///
///      storeColorSpace(colorSpace);
///
///      // colorSpace may be still alive after this scope ends.
///    }
///
///    void maybeStoreColorSpace(const lt::Ref<CGColorSpaceRef> &colorSpace) {
///      // Maybe store colorSpace for use.
///    }
///    @endcode@
///
///    This is the less common usage scenario, where the callee may or may not retain the argument,
///    and therefore needs to accept it as const reference (to avoid retaining it automatically).
///    Note that this case enforces the caller to use \c Ref and therefore prefer to pass raw
///    pointers as arguments.
///
///    For more information about pointer ownership and semantics, see
///    http://herbsutter.com/2013/06/05/gotw-91-solution-smart-pointer-parameters/
///
/// 3. Return \c lt::Ref from factory methods or functions that create a manually refcounted object:
///    @code@
///    lt::Ref<CGColorSpace> LTCreateColorSpaceWithFoo(Foo *foo);
///    @endcode@
///
///    For more information about this convention, see section #2 here:
///    http://herbsutter.com/2013/05/30/gotw-90-solution-factories/
///
/// 4. Use \c Ref::retain to retain an existing reference and manage it with a new \c Ref, instead
///    of taking over an existing retainment:
///    @code@
///    void retainAndCreateRef(CGContextRef context) {
///      auto holdContext = lt::Ref<CGContext>::retain(context);
///    }
///    @endcode@
///
///    This should be used instead of the following code that will result in double-free and
///    possibly a crash:
///    @code@
///    void doubleFreeAndCrash(CGContextRef context) {
///      // Must retain first!
///      auto holdContext = lt::Ref<CGContext>(context);
///    }
///    @endcode@
///
/// @note in contrast to std::unique_ptr, this class is templated on the reference type, and not on
/// the element type the reference points to. This is because, in iOS, we almost always don't have
/// access to the actual element type, and the reference type points to an opaque object.
template <typename T>
class Ref {
public:
  static_assert(lt::IsCoreFoundationObjectRef<T>::value, "Ref works only with Core Foundation "
                "types enabled by the lt::IsCoreFoundationObjectRef type trait");

  /// Type of the pointer this Ref holds;
  using PointerType = T;

  /// Constructs a Ref with a \c nullptr reference.
  constexpr Ref() noexcept : _ref(nullptr) {};

  /// Constructs a Ref with a \c nullptr reference.
  constexpr Ref(nullptr_t) noexcept : _ref(nullptr) {};

  /// Constructs a Ref with a given \c ref.
  explicit constexpr Ref(PointerType CF_RELEASES_ARGUMENT ref) noexcept : _ref(ref) {}

  /// Copy constructor.
  constexpr Ref(const Ref &other) noexcept : _ref((PointerType)incRef(other._ref)) {}

  /// Copy constructor with type covariance support.
  template <typename U>
  constexpr Ref(const Ref<U> &other,
      typename std::enable_if<
        std::is_convertible<typename Ref<U>::PointerType, PointerType>::value
      >::type * = 0) noexcept : _ref((PointerType)incRef(other._ref)) {}

  /// Move constructor.
  constexpr Ref(Ref &&other) noexcept : _ref(other._ref) {
    other._ref = nullptr;
  }

  /// Move constructor with type covariance support.
  template <typename U>
  constexpr Ref(Ref<U> &&other,
      typename std::enable_if<
        std::is_convertible<typename Ref<U>::PointerType, PointerType>::value
      >::type * = 0) noexcept : _ref(other._ref) {
    other._ref = nullptr;
  }

  /// Assignment operator.
  constexpr Ref &operator=(const Ref &other) noexcept {
    reset((PointerType)incRef((CFTypeRef)other._ref));
    return *this;
  }

  /// Assignment operator with type covariance support.
  template <typename U>
  constexpr typename std::enable_if<
    std::is_convertible<typename Ref<U>::PointerType, PointerType>::value, Ref &
  >::type &operator=(const Ref &other) noexcept {
    reset((PointerType)incRef((CFTypeRef)other._ref));
    return *this;
  }

  /// Move assignment operator.
  constexpr Ref &operator=(Ref<PointerType> &&other) noexcept {
    auto ref = other._ref;
    other._ref = nullptr;
    reset(ref);
    return *this;
  }

  /// Move assignment operator with type covariance support.
  template <typename U>
  constexpr typename std::enable_if<
    std::is_convertible<typename Ref<U>::PointerType, PointerType>::value, Ref &
  >::type &operator=(Ref<U> &&other) noexcept {
    auto ref = other._ref;
    other._ref = nullptr;
    reset(ref);
    return *this;
  }

  /// Releases the reference if it's not \c nullptr.
  ~Ref() {
    reset(nullptr);
  }

  /// \c true if this class currently owns a reference.
  explicit constexpr operator bool() const noexcept {
    return _ref != nullptr;
  }

  /// Returns the owned reference.
  constexpr PointerType get() const noexcept {
    return _ref;
  }

  /// Releases the ownership of the managed object if it exists and returns the pointer to the
  /// managed reference. After this call, this object will not own a reference.
  constexpr PointerType release() noexcept LT_WARN_UNUSED_RESULT {
    PointerType ref = _ref;
    _ref = nullptr;
    return ref;
  }

  /// Resets the Ref by releasing the previously held reference and acquiring the given \c ref. If
  /// Ref is currently pointing to \c nullptr, no action is performed.
  constexpr void reset(PointerType ref = nullptr) noexcept {
    decRef(_ref);
    _ref = ref;
  }

  /// Retain the given \c ref and return a new \c Ref that is responsible for releasing it.
  static constexpr inline Ref<PointerType> retain(PointerType ref) {
    return Ref(ref ? (PointerType)CFRetain(ref) : nullptr);
  }

private:
  /// Allows accessing private members of \c Ref<U> from \c Ref<T>.
  template <typename U>
  friend class Ref;

  /// Increments the retain count of the ref.
  static constexpr CFTypeRef incRef(CFTypeRef ref) noexcept {
    return ref ? CFRetain(ref) : nullptr;
  }

  /// Decrements the retain count of the ref.
  static constexpr void decRef(CFTypeRef ref) noexcept {
    if (ref) {
      CFRelease(ref);
    }
  }

  /// Pointer managed by this Ref.
  PointerType _ref;
};

/// Creates a reference with automatic template argument deduction, i.e. instead of writing:
/// <tt>auto ref = Ref<Foo>(foo);</tt>, one can just write: <tt>auto ref = makeRef(foo);</tt>.
template <typename T>
constexpr auto makeRef(T &&reference) noexcept {
  return lt::Ref<typename std::remove_reference<T>::type>(std::forward<T>(reference));
}

template <typename T, typename U>
constexpr bool operator==(const Ref<T> &x, const Ref<U> &y) noexcept {
  return x.get() == y.get();
}

template <typename T>
constexpr bool operator==(nullptr_t, const Ref<T> &x) noexcept {
  return !x;
}

template <typename T>
constexpr bool operator==(const Ref<T> &x, nullptr_t) noexcept {
  return !x;
}

template <typename T, typename U>
constexpr bool operator!=(const Ref<T> &x, const Ref<U> &y) noexcept {
  return !(x == y);
}

template <typename T>
constexpr bool operator!=(nullptr_t, const Ref<T> &x) noexcept {
  return static_cast<bool>(x);
}

template <typename T>
constexpr bool operator!=(const Ref<T> &x, nullptr_t) noexcept {
  return static_cast<bool>(x);
}

} // namespace lt

#endif
