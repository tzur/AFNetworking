// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRReceiptValidationStatus;

@protocol BZRTimeProvider;

/// Provider that provides the receipt validation status using an underlying provider and caches the
/// receipt validation status to storage.
@interface BZRCachedReceiptValidationStatusProvider : NSObject <BZRReceiptValidationStatusProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorage, used to pesist receipt validation status, with
/// \c timeProvider used to persist the time the receipt was validated, and with
/// \c underlyingProvider, used to fetch the receipt validation status.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
                           timeProvider:(id<BZRTimeProvider>)timeProvider
                     underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
    NS_DESIGNATED_INITIALIZER;

/// Expires the subscription of the user.
- (void)expireSubscription;

/// Holds the most recent receipt validation status that was fetched successfully. If
/// \c fetchReceiptValidationStatus has never completed successfully, this holds the value loaded
/// using \c keychainStorage. If the value doesn't exist in storage, this property will be \c nil.
/// KVO compliant.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// Holds the date of the last receipt validation. \c nil if \c receiptValidationStatus is \c nil.
@property (readonly, nonatomic, nullable) NSDate *lastReceiptValidationDate;

@end

NS_ASSUME_NONNULL_END
