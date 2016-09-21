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

@end

NS_ASSUME_NONNULL_END
