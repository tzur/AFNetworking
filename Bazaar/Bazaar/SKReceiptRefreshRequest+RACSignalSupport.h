// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Adds reactive interface to \c SKReceiptRefreshRequest.
@interface SKReceiptRefreshRequest (RACSignalSupport)

/// Unites \c SKRequestDelegate callbacks into a signal that can be used to track request's status.
/// The signal will not fire until \c start is invoked on the receiver.
///
/// Returns a signal that sends no values, it completes when \c requestDidFinish: is invoked on the
/// receiver's delegate or when the receiver deallocates. The signal errs when
/// \c -request:didFailWithError: is invoked on the receiver's delegate.
///
/// @return <tt>RACSignal</tt>.
///
/// @note As a side effect of this method the receiver's delegate will be replaced. Setting the
/// receiver's \c delegate property afterward is considered undefined behavior.
- (RACSignal *)bzr_statusSignal;

@end

NS_ASSUME_NONNULL_END
