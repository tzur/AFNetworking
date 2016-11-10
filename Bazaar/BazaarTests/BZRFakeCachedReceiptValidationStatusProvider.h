// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake provider that provides a \c BZRReceiptValidationStatus manually injected to its
/// \c receiptValidationStatus property.
@interface BZRFakeCachedReceiptValidationStatusProvider : BZRCachedReceiptValidationStatusProvider

/// Initializes with \c keychainStorage set to \c OCMClassMock([BZRKeychainStorage class]) and
/// \c underlyingProvider set to \c OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider)).
- (instancetype)init;

/// A replaceable receipt validation status.
@property (strong, readwrite, nonatomic, nullable) BZRReceiptValidationStatus *
    receiptValidationStatus;

/// A replaceable last receipt validation date.
@property (strong, readwrite, nonatomic, nullable) NSDate *lastReceiptValidationDate;

/// \c YES if \c fetchReceiptValidationStatus was called, \c NO otherwise.
@property (readonly, nonatomic) BOOL wasFetchReceiptValidationStatusCalled;

/// The signal that is returned from \c fetchReceiptValidationStatus. If \c nil,
/// \c +[RACSignal empty] is returned.
@property (strong, nonatomic, nullable) RACSignal *signalToReturnFromFetchReceiptValidationStatus;

/// \c YES if \c expireSubscription was called, \c NO otherwise.
@property (readonly, nonatomic) BOOL wasExpireSubscriptionCalled;

@end

NS_ASSUME_NONNULL_END
