// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Category with convenience methods for signals.
@interface RACSignal (CameraUI)

/// Returns a signal that maps each \c RACTuple from the receiver to the first item of the tuple.
/// The returned signal completes and errs with the source signal.
/// Raises an exception if the receiver is carrying anything other than \c RACTuple.
- (RACSignal *)cui_unpackFirst;

/// Returns a signal that maps each \c RACTuple from the receiver to the \c index item of the tuple.
/// The returned signal completes and errs with the source signal.
/// Raises an exception if the receiver is carrying anything other than \c RACTuple or if any
/// \c RACTuple doesn't contain an item at the given \c index.
- (RACSignal *)cui_unpack:(NSUInteger)index;

/// Returns a signal that sends the results of applying binary logical AND operation on the last
/// \c NSNumber values sent by the receiver and the given signal (similar behavior as
/// \c combineLatest on both signals and applying \c RACSiganl's \c -and operator on the combined
/// signal).
///
/// The returned signal errs when the receiver or the given signal err, and completes when both the
/// receiver and the given sigal complete.
///
/// Raises an exception if the receiver or the given signal are carrying anything other than
/// \c NSNumber.
///
/// @note This is similar to \c RACSiganl's \c -and operator, which can't compile in Objective-C++.
- (RACSignal *)cui_and:(RACSignal *)other;

@end

NS_ASSUME_NONNULL_END
