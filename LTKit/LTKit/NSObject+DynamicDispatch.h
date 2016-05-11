// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Category for enabling dynamic selector dispatching, as a safer replacement for
/// <tt>-[NSObject performSelector:]</tt>.
///
/// While the Objective-C runtime enables dynamic dispatching using \c -[NSObject performSelector:],
/// it suffers from two major drawbacks:
/// - Performing a selector on an object that doesn't respond to it will raise an exception and
///   crash the app.
/// - Undocumented: performing a selector with a return type that is not an Objective-C object is
///   not supported. Moreover, in the case of dynamic dispatching where the selector name is
///   determined in runtime and not in compile time, ARC assumes that it should retain the returned
///   value and release it when it is not used. If the selector returns \c void or a primitive
///   object, retaining the returned value may result in a crash.
///
/// This category mitigates the issues described above using the following methods:
/// - Before dispatching the selector, this category verifies that the object responds to that
///   selectors, and if it doesn't, returns \c nil and ignores the operation.
/// - The return type of the method is dynamically inspected at runtime, which allows this category
///   to call one of the two static variants of the selector's signature: one that returns a \c void
///   return value and the other which returns an Objective-C object. This allows the compiler to
///   generate proper ARC directives in compile time.
///
/// @note since this category inspects the method signature of the selector, dynamically dispatching
/// a selector is relatively slower (could be at least one order of magnitude slower than directly
/// calling it in code).
///
/// @important clients should be aware of these issues when dynamically dispatching a selector:
///   - If the dispatched selector returns \c void, the returned value will be \c nil.
///   - Dispatching currently supports selectors that return either void (\c v) or an Objective-C
///     object (\c @). The behavior of dispatching other selectors is undefined.
///   - Methods that are marked with \c ns_returns_retained attribute and methods that start with
///     \c alloc, \c new and \c copy will return a retained object. Since ARC cannot differ such
///     methods from common methods that do not return a retained object, it will not balance the
///     retain call with a release and therefore will produce a leak. The client of this category
///     must ensure that such selectors will not be called as it is impossible to know this in
///     runtime.
@interface NSObject (DynamicDispatch)

/// Performs the selector on the receiver if the receiver responds to it. If the selector is not
/// available on the receiver, no action is taken.
///
/// @important see \c NSObject(DynamicDispatch) header for possible pitfalls when using this method.
- (nullable id)lt_dispatchSelector:(SEL)selector;

/// Performs the selector on the receiver with the given object if the receiver responds to it.
/// If the selector is not available on the receiver, no action is taken.
///
/// @important see \c NSObject(DynamicDispatch) header for possible pitfalls when using this method.
- (nullable id)lt_dispatchSelector:(SEL)selector withObject:(id)object;

/// Performs the selector on the receiver with the given objects if the receiver responds to it.
/// If the selector is not available on the receiver, no action is taken.
///
/// @important see \c NSObject(DynamicDispatch) header for possible pitfalls when using this method.
- (nullable id)lt_dispatchSelector:(SEL)selector withObject:(id)object withObject:(id)anotherObject;

@end

NS_ASSUME_NONNULL_END
