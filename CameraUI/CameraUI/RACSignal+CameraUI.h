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

@end

NS_ASSUME_NONNULL_END
