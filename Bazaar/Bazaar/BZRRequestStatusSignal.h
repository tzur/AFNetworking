// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for adding reactive interface to \c SKRequest classes.
@protocol BZRRequestStatusSignal

/// Returns a signal that is used to track the request's status. The values are delivered on the
/// main thread.
///
/// The signal will not send values until \c start is invoked on the receiver. The signal
/// completes when \c requestDidFinish: is invoked on the receiver's delegate or when the receiver
/// deallocates. The signal errs when \c -request:didFailWithError: is invoked on the receiver's
/// delegate. The signal will stop sending values when \c cancel is invoked on the receiver.
///
/// @return <tt>RACSignal</tt>.
- (RACSignal *)statusSignal;

@end

NS_ASSUME_NONNULL_END
