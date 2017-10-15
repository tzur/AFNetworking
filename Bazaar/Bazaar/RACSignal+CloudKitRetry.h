// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Adds operator to conditionally retry CloudKit operations only for errors that suggest retrying.
@interface RACSignal (CloudKitRetry)

/// Returns a new signal that handles an error that is sent. On errors that provide
/// \c CKErrorRetryAfterKey key in their \c userInfo dictionary the signal will be retried at most
/// \c retryCount times. The delay between retries is the number of seconds defined by the
/// \c CKErrorRetryAfterKey entry in the \c userInfo dictionary. Any other error will be propagated.
- (instancetype)bzr_retryCloudKitErrorIfNeeded:(NSUInteger)retryCount;

@end

NS_ASSUME_NONNULL_END
