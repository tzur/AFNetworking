// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Adds reactive interface to \c SKProductsRequest.
@interface SKProductsRequest (RACSignalSupport)

/// Unites \c SKProductRequestDelegate callbacks into a signal that can be used to track request's
/// status. The signal will not fire until \c start is invoked on the receiver.
///
/// Returns a signal that sends \c SKProductsResponse value when the receiver invokes
/// \c productRequest:didReceiveResponse: on its delegate. The signal completes when the receiver
/// invokes \c requestDidFinish: on its delegate or when the receiver deallocates and errs when the
/// receiver invokes \c -request:didFailWithError: on its delegate.
///
/// @return <tt>RACSignal<SKProductResponse></tt>.
///
/// @note As side effect of this method the receiver's delegate will be replaced. Setting the
/// receiver's \c delegate property afterward is considered undefined behavior.
- (RACSignal *)bzr_statusSignal;

@end

NS_ASSUME_NONNULL_END
