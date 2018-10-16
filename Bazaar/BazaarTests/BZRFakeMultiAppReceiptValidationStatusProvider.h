// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiAppReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake provider that provides a \c BZRReceiptValidationStatus manually injected to its
/// \c receiptValidationStatus property.
@interface BZRFakeMultiAppReceiptValidationStatusProvider :
    BZRMultiAppReceiptValidationStatusProvider

/// Initializes with mock arguments.
- (instancetype)init;

/// A replaceable receipt validation status.
@property (readwrite, atomic, nullable) BZRReceiptValidationStatus
    *aggregatedReceiptValidationStatus;

/// A replaceable multi-app receipt validation status.
@property (readwrite, atomic, nullable) NSDictionary<NSString *, BZRReceiptValidationStatus *>
    *multiAppReceiptValidationStatus;

/// \c YES if \c fetchReceiptValidationStatus was called, \c NO otherwise.
@property (readonly, nonatomic) BOOL wasFetchReceiptValidationStatusCalled;

/// The signal that is returned from \c fetchReceiptValidationStatus. If \c nil,
/// \c +[RACSignal empty] is returned.
@property (strong, nonatomic, nullable) RACSignal *signalToReturnFromFetchReceiptValidationStatus;

@end

NS_ASSUME_NONNULL_END
